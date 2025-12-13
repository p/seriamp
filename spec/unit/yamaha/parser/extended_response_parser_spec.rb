# frozen_string_literal: true

require 'seriamp/yamaha/parser/extended_response_parser'
require 'spec_helper'

describe Seriamp::Yamaha::Parser::ExtendedResponseParser do
  describe '.parse' do
    let(:parsed) { described_class.parse(response_str) }

    context 'when response is totally invalid' do
      let(:response_str) { "bogus" }
      it 'raises an exception' do
        lambda do
          parsed
        end.should raise_error(Seriamp::UnexpectedResponse, /Invalid response: expected to start with 20/)
      end
    end

    context 'when length is bogus' do
      let(:response_str) { "20bogus" }
      it 'raises an exception' do
        lambda do
          parsed
        end.should raise_error(Seriamp::UnexpectedResponse, /Invalid response: bogus length/)
      end
    end

    context 'when checksum is wrong' do
      let(:response_str) { "2030bogus" }
      it 'raises an exception' do
        lambda do
          parsed
        end.should raise_error(Seriamp::UnexpectedResponse, /Broken status response: calculated checksum .*, received checksum/)
      end
    end
  end
end
