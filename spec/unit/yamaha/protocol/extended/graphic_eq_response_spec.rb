require 'spec_helper'

describe Seriamp::Yamaha::Protocol::Extended::GraphicEqResponse do
  let(:response) do
    described_class.new('030', '2210')
  end

  describe '#to_state' do
    it 'returns expected result' do
      response.to_state.should == {
        front_left_geq_160: 0.5,
      }
    end
  end
end
