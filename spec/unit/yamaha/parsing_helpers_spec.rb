# frozen_string_literal: true

require 'seriamp/yamaha/parsing_helpers'
require 'spec_helper'

describe Seriamp::Yamaha::ParsingHelpers do
  let(:host) do
    _described_class = described_class

    Class.new do
      include _described_class
    end.new
  end

  describe '#parse_half_db_volume' do
    subject { host.send(:parse_half_db_volume, value, :test) }

    context 'mute' do
      let(:value) { '00' }
      it 'decodes to nil' do
        subject.should be nil
      end
    end

    context 'min' do
      let(:value) { '27' }
      it 'decodes to -80' do
        subject.should be -80.0
      end
    end

    context '0 dB' do
      let(:value) { 'C7' }
      it 'decodes to 0' do
        subject.should be 0.0
      end
    end

    context 'max' do
      let(:value) { 'E8' }
      it 'decodes to 16.5' do
        subject.should be 16.5
      end
    end
  end
end
