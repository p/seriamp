# frozen_string_literal: true

require 'spec_helper'

describe Seriamp::Sonamp::Executor do
  let(:client) do
    double('mock client')
  end

  let(:executor) do
    described_class.new(client)
  end

  describe 'power' do
    it 'works' do
      client.should receive(:set_zone_power).with(1, true)
      executor.run_command('power', *%w(1 on)).should be nil
    end
  end

  describe 'off' do
    it 'works' do
      client.should receive(:set_zone_power).with(1, false)
      client.should receive(:set_zone_power).with(2, false)
      client.should receive(:set_zone_power).with(3, false)
      client.should receive(:set_zone_power).with(4, false)
      executor.run_command('off').should be nil
    end
  end

  describe 'zvol' do
    it 'works' do
      client.should receive(:set_zone_volume).with(2, 50)
      executor.run_command('zvol', *%w(2 50)).should be nil
    end
  end

  describe 'cvol' do
    it 'works' do
      client.should receive(:set_channel_volume).with(2, 50)
      executor.run_command('cvol', *%w(2 50)).should be nil
    end
  end

  describe 'zmute' do
    it 'works' do
      client.should receive(:set_zone_mute).with(1, true)
      executor.run_command('zmute', *%w(1 true)).should be nil
    end
  end

  describe 'cmute' do
    it 'works' do
      client.should receive(:set_channel_mute).with(2, true)
      executor.run_command('cmute', *%w(2 on)).should be nil
    end
  end
end
