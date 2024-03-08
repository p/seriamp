# frozen_string_literal: true

require 'spec_helper'

describe Seriamp::Yamaha::Helpers do
  let(:host) do
    Class.new do
      include Seriamp::Yamaha::Helpers
    end.new
  end

  describe '#serialize_volume' do
    context '0.5 dB step' do
      it 'translates min value' do
        host.serialize_volume(-6, -6, 0, 0.5).should == '00'
      end

      it 'translates zero value' do
        host.serialize_volume(0, -6, 0, 0.5).should == '0C'
      end

      it 'translates max value' do
        host.serialize_volume(6, -6, 0, 0.5).should == '18'
      end

      it 'translates negative fractional value' do
        host.serialize_volume(-5.5, -6, 0, 0.5).should == '01'
      end

      it 'translates positive fractional value' do
        host.serialize_volume(5.5, -6, 0, 0.5).should == '17'
      end
    end
  end

  describe '#parse_sequence' do
    context '0.5 dB step' do
      it 'translates min value' do
        host.parse_sequence('00', '00', -6, 6, 0.5).should == -6
      end

      it 'translates zero value' do
        host.parse_sequence('0C', '00', -6, 6, 0.5).should == 0
      end

      it 'translates max value' do
        host.parse_sequence('18', '00', -6, 6, 0.5).should == 6
      end

      it 'translates negative fractional value' do
        host.parse_sequence('01', '00', -6, 6, 0.5).should == -5.5
      end

      it 'translates positive fractional value' do
        host.parse_sequence('17', '00', -6, 6, 0.5).should == 5.5
      end
    end

    context 'upper bound' do
      it 'works' do
        host.parse_sequence('09', '00', -30, 15, 5).should == 15
      end
    end
  end

  describe '#encode_sequence' do
    it 'encodes to 1-byte value' do
      host.encode_sequence(4, '1', 0, 5, 1).should == '5'
    end

    it 'encodes to 2-byte value' do
      host.encode_sequence(4, '01', 0, 5, 1).should == '05'
    end

    it 'encodes to 3-byte value' do
      host.encode_sequence(4, '001', 0, 5, 1).should == '005'
    end
  end

  describe '#serialize_parametric_frequency' do
    it 'serializes exact min frequency' do
      host.serialize_parametric_frequency(31.3).should == '06'
    end

    it 'serializes less than min frequency' do
      host.serialize_parametric_frequency(1).should == '06'
    end

    it 'serializes exact max frequency' do
      host.serialize_parametric_frequency(16000).should == '3C'
    end

    it 'serializes more than max frequency' do
      host.serialize_parametric_frequency(202020.0).should == '3C'
    end

    it 'serializes exact middle frequency' do
      host.serialize_parametric_frequency(198.4).should == '16'
    end

    it 'serializes slightly under middle frequency' do
      host.serialize_parametric_frequency(197).should == '16'
    end

    it 'serializes slightly over middle frequency' do
      host.serialize_parametric_frequency(199).should == '16'
    end

    it 'serializes close to but over min frequency' do
      host.serialize_parametric_frequency(32).should == '06'
    end

    it 'serializes close to but under second frequency' do
      host.serialize_parametric_frequency(38).should == '08'
    end
  end

  describe '#serialize_parametric_q' do
    it 'exact min q' do
      host.serialize_parametric_q(0.5).should == '0'
    end

    it 'less than min q' do
      host.serialize_parametric_q(0.2).should == '0'
    end

    it 'exact max q' do
      host.serialize_parametric_q(10.8).should == 'D'
    end

    it 'more than max q' do
      host.serialize_parametric_q(1000).should == 'D'
    end

    it 'just over min q' do
      host.serialize_parametric_q(0.55).should == '0'
    end

    it 'just under second q' do
      host.serialize_parametric_q(0.6).should == '1'
    end
  end
end
