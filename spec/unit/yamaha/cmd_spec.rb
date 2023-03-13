# frozen_string_literal: true

require 'spec_helper'

describe 'yamaha commands' do
  let(:client_cls) { Seriamp::Yamaha::Client }

  describe '#initialize' do
    it 'works' do
      Seriamp::Cmd.new(module_name: 'yamaha')
    end
  end

  let(:args) { [] }
  let(:stdin_c) { '' }
  let(:stdin) { StringIO.new(stdin_c) }
  let(:extra_cmd_options) { {} }
  let (:cmd) { Seriamp::Cmd.new(args, stdin, module_name: 'yamaha', **extra_cmd_options) }

  describe '#run' do
    describe 'no command' do
      it 'reads stdin' do
        stdin.should receive(:each_line).and_return([])
        cmd.run
      end
    end

    context 'direct' do
      let(:client) { double('direct client') }

      describe '!status' do
        let(:args) { %w(status) }

        it 'works' do
          client.should_receive(:last_status)
          client_cls.should receive(:new).and_return(client)
          cmd.run
        end
      end

      describe 'bulk commands' do
        describe '!status' do
          let(:stdin_c) { 'status' }

          it 'works' do
            client.should_receive(:last_status)
            client_cls.should receive(:new).and_return(client)
            cmd.run
          end
        end

        describe 'dash syntax' do
          let(:stdin_c) { "pure-direct on" }

          it 'works' do
            client.should_receive(:set_pure_direct).with(true)
            client_cls.should receive(:new).and_return(client)
            cmd.run
          end
        end

        describe 'underscore syntax' do
          let(:stdin_c) { "pure_direct on" }

          it 'works' do
            client.should_receive(:set_pure_direct).with(true)
            client_cls.should receive(:new).and_return(client)
            cmd.run
          end
        end

        describe 'two commands' do
          let(:stdin_c) { "status\npure-direct on" }

          it 'works' do
            client.should_receive(:last_status)
            client.should_receive(:set_pure_direct).with(true)
            client_cls.should receive(:new).and_return(client)
            cmd.run
          end
        end
      end
    end

    context 'via service' do
      let(:client) { double('service client') }
      let(:args) { %w(-s http://service/) + extra_args }
      let(:extra_args) { [] }
      let(:response) { double('mock response') }

      before do
        Seriamp::FaradayFacade.should receive(:new).and_return(client)
      end

      describe '!status' do
        let(:extra_args) { %w(status) }

        it 'works' do
          response.should receive(:body).and_return({})
          client.should_receive(:post!).with('', body: 'status').and_return(response)
          cmd.run
        end
      end

      describe 'bulk commands' do
        describe '!status' do
          let(:stdin_c) { 'status' }

          it 'works' do
            response.should receive(:body).and_return({})
            client.should_receive(:post!).with('', body: 'status').and_return(response)
            cmd.run
          end
        end

        describe 'dash syntax' do
          let(:stdin_c) { "pure-direct on" }

          it 'forwards as is' do
            response.should receive(:body).and_return({})
            client.should_receive(:post!).with('', body: 'pure-direct on').and_return(response)
            cmd.run
          end
        end

        describe 'underscore syntax' do
          let(:stdin_c) { "pure_direct on" }

          it 'forwards as is' do
            response.should receive(:body).and_return({})
            client.should_receive(:post!).with('', body: 'pure_direct on').and_return(response)
            cmd.run
          end
        end

        describe 'two commands' do
          let(:stdin_c) { "status\npure-direct on" }

          it 'works' do
            response.should receive(:body).and_return({})
            client.should_receive(:post!).with('', body: "status\npure-direct on").and_return(response)
            cmd.run
          end
        end
      end
    end
  end
end
