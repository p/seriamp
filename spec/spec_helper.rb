# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'byebug'
require 'seriamp/all'
require 'rack/test'
require 'mock_serial_port_backend'
require 'timeout_backend'

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
      Process.waitpid(pid)

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

end

module InstanceMethods
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
