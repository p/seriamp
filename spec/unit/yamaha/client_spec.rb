# frozen_string_literal: true

require 'spec_helper'

describe Seriamp::Yamaha::Client do
  describe '#initialize' do
    it 'works' do
      described_class.new
    end
  end

  describe '#parse_response' do
    let(:client) { described_class.new }
    let(:parsed) { client.send(:parse_response, response) }

    context 'power on' do
      let(:response) { "\u0002002002\u0003" }
      it 'parses' do
        parsed.should == {
          control_type: :rs232c,
          state: {main_power: true, zone2_power: false, zone3_power: false},
        }
      end
    end
  end
end
