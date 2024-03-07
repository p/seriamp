require 'spec_helper'

describe 'Yamaha integration' do
  require_integration_device :yamaha
  let(:device) { integration_device(:yamaha) }

  let(:logging_options) do
    {logger: logger, backend: :logging_serial_port}.freeze
  end
  let(:logging_options) { {}.freeze }

  let(:logger) { Logger.new(STDERR) }
  let(:client) { Seriamp::Yamaha::Client.new(**logging_options.merge(device: device)) }
  let(:executor) { Seriamp::Yamaha::Executor.new(client) }

  describe 'dev-status' do
    before do
      client.main_power.should be true
    end

    let(:result) { executor.run_command('dev-status') }

    it 'works' do
      # Result is printed to standard output
      result.should be nil
    end
  end

  describe 'volume' do
    before do
      client.main_power.should be true
    end

    context 'get' do
      it 'works' do
        executor.run_command('volume').should be_a(Float)
      end
    end

    context 'set' do
      it 'works' do
        executor.run_command('volume', '-79.5').should == -79.5
        executor.run_command('volume').should == -79.5
        executor.run_command('volume', '-79').should == -79.0
        executor.run_command('volume').should == -79.0
      end
    end
  end

  describe 'main-speaker-tone-bass' do
    before do
      client.main_power.should be true
    end

    context 'gain only' do
      it 'works' do
        executor.run_command('main-speaker-tone-bass', '0').should be nil
        resp = executor.run_command('main-speaker-tone-bass')
        resp.fetch(:gain).should == 0

        executor.run_command('main-speaker-tone-bass', '-2.5').should be nil
        resp = executor.run_command('main-speaker-tone-bass')
        resp.fetch(:gain).should == -2.5
      end
    end

    context 'gain + frequency' do
      it 'works' do
        skip 'requires RX-V3xxx'

        executor.run_command('main-speaker-tone-bass', '0', '125').should be nil
        resp = executor.run_command('main-speaker-tone-bass')
        resp.fetch(:gain).should == 0
        resp.fetch(:frequency).should == 125

        executor.run_command('main-speaker-tone-bass', '-2.5', '500').should be nil
        resp = executor.run_command('main-speaker-tone-bass')
        resp.fetch(:gain).should == -2.5
        resp.fetch(:frequency).should == 500
      end
    end
  end

  describe 'graphic eq' do
    before do
      client.main_power.should be true
    end

    context 'get channel + band' do
      it 'works' do
        executor.run_command('graphic-eq', 'center', '1000').should be_a(Float)
      end
    end

    context 'get channel' do
      let(:result) do
        executor.run_command('graphic-eq', 'center')
      end

      it 'works' do
        result.should be_a(Hash)
        result.keys.map(&:class).uniq.should == [Integer]
        result.values.map(&:class).uniq.should == [Float]
      end
    end

    context 'set' do
      it 'works' do
        executor.run_command('graphic-eq', 'center', '1000', '-2').should be nil
        executor.run_command('graphic-eq', 'center', '1000').should == -2.0

        executor.run_command('graphic-eq', 'center', '1000', '-1.5').should be nil
        executor.run_command('graphic-eq', 'center', '1000').should == -1.5
      end
    end
  end

  describe 'parametric eq' do
    before do
      client.main_power.should be true
    end

    context 'get channel + band' do
      it 'works' do
        executor.run_command('parametric-eq', 'center', '1000').should be_a(Float)
      end
    end

    context 'get channel' do
      let(:result) do
        executor.run_command('parametric-eq', 'center')
      end

      it 'works' do
        result.should be_a(Hash)
        result.keys.map(&:class).uniq.should == [Integer]
        result.values.map(&:class).uniq.should == [Float]
      end
    end

    context 'set' do
      it 'works' do
        executor.run_command('parametric-eq', 'center', '1000', '-2').should be nil
        executor.run_command('parametric-eq', 'center', '1000').should == -2.0

        executor.run_command('parametric-eq', 'center', '1000', '-1.5').should be nil
        executor.run_command('parametric-eq', 'center', '1000').should == -1.5
      end
    end
  end
end
