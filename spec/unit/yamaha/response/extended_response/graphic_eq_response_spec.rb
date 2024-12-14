require 'spec_helper'

describe Seriamp::Yamaha::Response::ExtendedResponse::GraphicEqResponse do
  let(:response) do
    # RX-V1800
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
