# frozen_string_literal: true

require 'seriamp/yamaha/response'
require 'spec_helper'

describe Seriamp::Yamaha::Response do
  describe '.parse' do
    let(:parsed) { described_class.parse(response_str) }
    
    context 'status response' do
      let(:response_str) { "\x12R0225JB5@E01900020001C0ACE88003140200000000200F1020001002828262626262628282800020114140000A014055112000020040020001000000000002000000115077000121100A0A01FFFF0110000A0014A0014210A0A00FF101102D\x03" }
      
      it 'returns an instance of correct response class' do
        parsed.should be_a(Seriamp::Yamaha::Response::StatusResponse)
      end
    end
    
    context 'command response' do
      let(:response_str) { "\x0200263B\x03" }
      
      it 'returns an instance of correct response class' do
        parsed.should be_a(Seriamp::Yamaha::Response::CommandResponse)
        parsed.control_type.should be :rs232
        parsed.guard.should be nil
        parsed.state.should == {main_volume: -70}
      end
    end
    
    context 'extended response' do
      let(:response_str) { "\x142012011002309\x20\x20\x20\x20\x20\x20\x20\x20\x20A5\x03" }
      
      it 'returns an instance of correct response class' do
        pending
        parsed.should be_a(Seriamp::Yamaha::Response::ExtendedResponse)
      end
    end
  end
end
