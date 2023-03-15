# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'byebug'
require 'seriamp/all'
require 'rack/test'

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
