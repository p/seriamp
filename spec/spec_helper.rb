# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'byebug'
require 'seriamp/all'
require 'rack/test'
require 'test_backends'
require 'mock_serial_port_backend'

module InstanceMethods
  def tty_double
    double('tty device').tap do |device|
      allow(device).to receive(:baud=)
      allow(device).to receive(:data_bits=)
      allow(device).to receive(:stop_bits=)
      allow(device).to receive(:parity=)
      allow(device).to receive(:flow_control=)
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
end

RSpec.configure do |rspec|
  rspec.expect_with(:rspec) do |c|
    c.syntax = [:should, :expect]
  end
  rspec.mock_with(:rspec) do |mocks|
    mocks.syntax = [:should, :expect]
  end

  rspec.include InstanceMethods
end
