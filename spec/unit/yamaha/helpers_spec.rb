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

  describe '#parse_volume' do
    context '0.5 dB step' do
      it 'translates min value' do
        host.parse_volume('00', '00', -6, 6, 0.5).should == -6
      end

      it 'translates zero value' do
        host.parse_volume('0C', '00', -6, 6, 0.5).should == 0
      end

      it 'translates max value' do
        host.parse_volume('18', '00', -6, 6, 0.5).should == 6
      end

      it 'translates negative fractional value' do
        host.parse_volume('01', '00', -6, 6, 0.5).should == -5.5
      end

      it 'translates positive fractional value' do
        host.parse_volume('17', '00', -6, 6, 0.5).should == 5.5
      end
    end
  end
end