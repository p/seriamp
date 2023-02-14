# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'byebug'
require 'seriamp/all'
require 'rack/test'

RSpec.configure do |rspec|
  rspec.expect_with(:rspec) do |c|
    c.syntax = [:should, :expect]
  end
  rspec.mock_with(:rspec) do |mocks|
    mocks.syntax = [:should, :expect]
  end
end
