require 'spec_helper'

describe Seriamp::Yamaha::Protocol::Extended::MainToneResponse do
  let(:response) do
    described_class.new('033', '0010C')
  end

  describe '#to_state' do
    it 'returns expected result' do
      response.to_state.should == {
        main_tone_speaker_bass: {frequency: 350, gain: 0},
      }
    end
  end
end
