require 'spec_helper'

describe Seriamp::Yamaha::Protocol::Extended::ParametricEqResponse do
  let(:response) do
    # RX-V3800
    described_class.new('034', '332E215')
  end

  describe '#to_state' do
    it 'returns expected result' do
      response.to_state.should == {
        front_right_peq_4: {frequency: 3170, gain: -3.5, q: 1.587},
      }
    end
  end
end
