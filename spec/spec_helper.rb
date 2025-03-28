# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'debug'
require 'byebug'
require 'seriamp/all'
require 'rack/test'
require 'mock_serial_port_backend'
require 'timeout_backend'

STDOUT.sync = true
STDERR.sync = true

module Utils
  module_function def localhost_host
    @localhost_host ||= begin
      socket = Socket.tcp('localhost', 49499, connect_timeout: 0.05)
      socket.close
      'localhost'
    rescue Errno::EADDRNOTAVAIL
      '127.0.0.1'
    end
  end

  module_function def app_integration_endpoint(port)
    "http://#{localhost_host}:#{port}"
  end

  module_function def stringify_keys(hash)
    Hash[hash.map do |k, v|
      [k.to_s, v]
    end]
  end
end

module ClassMethods
  def run_app(port, *args)
    args = args.flatten

    around do |example|
      unless port_available?(port)
        raise "Port not available: #{port}"
      end

      pid = fork do
        exec(*args)
      end

      wait_for_port_listening(port)

      example.run

      Process.kill('TERM', pid)
      kill_thread = Thread.new do
        sleep 3
        puts "Forcefully killing process #{pid} after 3 seconds"
        Process.kill('KILL', pid)
      end
      Process.waitpid(pid)
      kill_thread.kill

      wait_for_port_available(port)
    end
  end

  def require_integration_device(key)
    unless %i(integra sonamp yamaha).include?(key)
      raise ArgumentError, "Bad key: #{key}"
    end

    env_key = "SERIAMP_INTEGRATION_#{key.to_s.upcase}"
    if (ENV[env_key] || '').empty?
      before(:all) do
        skip "Set #{env_key}=/dev/ttyXXX in environment to run #{key} integration tests"
      end
    end
  end

  attr_accessor :_fixture_path

  def fixture_path(*args)
    case args.length
    when 0
      cls = self
      loop do
        value = cls.instance_variable_get('@fixture_path')
        return value if value
        cls = cls.superclass
        break if cls == Object
      end
    when 1
      @fixture_path = args.first
    else
      raise ArgumentError, "0 or 1 arguments permitted, given #{args.length}"
    end
  end

  def status_fixture?(path)
    comps = [File.dirname(__FILE__), 'fixtures', fixture_path, path + '.status']
    path = File.join(*comps.compact)
    File.exist?(path)
  end

end

module InstanceMethods
  def fixture_path
    self.class.fixture_path
  end

  def yaml_fixture(path)
    comps = [File.dirname(__FILE__), 'fixtures', fixture_path, path + '.yaml']
    path = File.join(*comps.compact)
    YAML.load(File.read(path))
  end

  def eval_fixture(path)
    comps = [File.dirname(__FILE__), 'fixtures', fixture_path, path + '.eval']
    path = File.join(*comps.compact)
    eval(File.read(path))
  end

  def status_fixture(path)
    comps = [File.dirname(__FILE__), 'fixtures', fixture_path, path + '.status']
    path = File.join(*comps.compact)
    eval(File.read(path))
  end

  def integration_device(key)
    unless %i(integra sonamp yamaha).include?(key)
      raise ArgumentError, "Bad key: #{key}"
    end

    env_key = "SERIAMP_INTEGRATION_#{key.to_s.upcase}"
    ENV.fetch(env_key)
  end

  def tty_double
    double('tty device').tap do |device|
      allow(device).to receive(:baud=)
      allow(device).to receive(:data_bits=)
      allow(device).to receive(:stop_bits=)
      allow(device).to receive(:parity=)
      allow(device).to receive(:flow_control=)
      allow(device).to receive(:rts=)
      allow(device).to receive(:close)
    end
  end

  def mock_serial_device(device)
    allow(Seriamp::UART).to receive(:open).and_return(device)
    allow(IO).to receive(:select)
    allow(Seriamp::UART).to receive(:set_rts)
  end

  def mock_serial_device_once(device)
    Seriamp::UART.should receive(:open).and_return(device)
    allow(IO).to receive(:select)
    allow(Seriamp::UART).to receive(:set_rts)
  end

  def setup_requests_responses(device, rr)
    rr.each do |req, *resps|
      expect(device).to receive(:syswrite).with(req)
      resps.each do |resp|
        expect(device).to receive(:read_nonblock).and_return(resp)
      end
    end
  end

  def setup_sonamp_requests_responses(device, rr)
    rr.each do |req, *resps|
      expect(device).to receive(:syswrite).with("#{req}\r")
      resps.each do |resp|
        expect(device).to receive(:read_nonblock).and_return("#{resp}\r")
      end
    end
  end

  def setup_ynca_requests_responses(device, rr)
    rr.each do |req, *resps|
      expect(device).to receive(:syswrite).with("#{req}\r\n")
      resps.each do |resp|
        expect(device).to receive(:read_nonblock).and_return("#{resp}\r\n")
      end
    end
  end

  def mock_scope(&block)
    RSpec::Mocks.with_temporary_scope(&block)
  end

  def get_json(uri)
    get(uri, nil, 'HTTP_ACCEPT' => 'application/json')
  end

  def response_json
    JSON.parse(last_response.body)
  end

  def port_available?(port, timeout: 1)
    socket = Socket.tcp(Utils.localhost_host, port, connect_timeout: timeout)
    if socket
      socket.close
      false
    else
      raise NotImplementedError
    end
  rescue Errno::ECONNREFUSED
    true
  end

  def port_listening?(port, timeout: 1)
    socket = Socket.tcp(Utils.localhost_host, port, connect_timeout: timeout)
    if socket
      socket.close
      true
    else
      raise NotImplementedError
    end
  rescue Errno::ECONNREFUSED
    false
  end

  def wait_for_port_listening(port)
    start = Seriamp::Utils.monotime
    loop do
      if port_listening?(port, timeout: 0.2)
        return
      end
      sleep 0.1
      break if Seriamp::Utils.monotime - start >= 2
    end
    raise "Port not listening: #{port}"
  end

  def wait_for_port_available(port)
    start = Seriamp::Utils.monotime
    loop do
      if port_available?(port, timeout: 0.2)
        return
      end
      sleep 0.1
      break if Seriamp::Utils.monotime - start >= 2
    end
    raise "Port not available: #{port}"
  end
end

module YamahaHelpers
  include Seriamp::Yamaha::Helpers

  alias :frame_ext_req :frame_extended_request
end

RSpec.configure do |rspec|
  rspec.expect_with(:rspec) do |c|
    c.syntax = [:should, :expect]
  end
  rspec.mock_with(:rspec) do |mocks|
    mocks.syntax = [:should, :expect]
  end

  rspec.extend ClassMethods
  rspec.include InstanceMethods
end
