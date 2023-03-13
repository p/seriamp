# frozen_string_literal: true

require 'spec_helper'

describe 'integra commands' do
  let(:client_cls) { Seriamp::Integra::Client }

  describe '#initialize' do
    it 'works' do
      Seriamp::Cmd.new([], StringIO.new(''), module_name: 'integra')
    end
  end

  let(:args) { [] }
  let(:stdin_c) { '' }
  let(:stdin) { StringIO.new(stdin_c) }
  let (:cmd) { Seriamp::Cmd.new(args, stdin, module_name: 'integra') }

  describe '#run' do
    describe 'no command' do
      it 'reads stdin' do
        stdin.should receive(:each_line).and_return([])
        cmd.run
      end
    end

    let(:client) { double('client') }

    describe '!status' do
      let(:args) { %w(status) }

      it 'works' do
        client.should_receive(:status)
        client_cls.should receive(:new).and_return(client)
        cmd.run
      end
    end

    describe '!volume' do
      let(:args) { %w(volume ,-80) }

      it 'works' do
        client.should_receive(:set_main_volume).with(-80)
        client_cls.should receive(:new).and_return(client)
        cmd.run
      end
    end

    describe 'bulk commands' do
      describe '!status' do
        let(:stdin_c) { 'status' }

        it 'works' do
          client.should_receive(:status)
          client_cls.should receive(:new).and_return(client)
          cmd.run
        end
      end

      describe 'dash syntax' do
        let(:stdin_c) { "pure-direct on" }

        it 'works' do
          pending
          client.should_receive(:set_pure_direct).with(true)
          client_cls.should receive(:new).and_return(client)
          cmd.run
        end
      end

      describe 'underscore syntax' do
        let(:stdin_c) { "pure_direct on" }

        it 'works' do
          pending
          client.should_receive(:set_pure_direct).with(true)
          client_cls.should receive(:new).and_return(client)
          cmd.run
        end
      end

      describe 'two commands' do
        let(:stdin_c) { "power zone2 on\npower zone3 on" }

        it 'works' do
          client.should_receive(:set_zone2_power).with(true)
          client.should_receive(:set_zone3_power).with(true)
          client_cls.should receive(:new).and_return(client)
          cmd.run
        end
      end
    end
  end
end
