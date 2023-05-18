# frozen_string_literal: true

require 'spec_helper'

describe Seriamp::Yamaha::Client do
  let(:client) { described_class.new }

  describe '#parse_status_response' do
    let(:parsed) { client.send(:parse_status_response, status_response) }

    context 'RX-V1800' do

      let(:status_response) do
        "R0226JB5@E0190002040050B94D3403140300000108200F1020001002828282828282828282800030114140000A00400511000000000002000200000000000200000010504D00012100070E01FFFF0110000A0014A0014210A0A00FF101101E"
      end

      it 'works' do
        parsed.should == {}
      end
    end

    context 'RX-V2700' do

      let(:status_response) do
        "R0212IAE@E01900020430507B778003140500000108200F1020001002828262626262628282800020114140000A114055110000020240120001000000103002000000115077000121100A0A01FFFF0110000A0014A0014210A0A00A8"
      end

      it 'works' do
        parsed.should == {}
      end
    end
  end
end
