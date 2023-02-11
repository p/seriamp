# frozen_string_literal: true

require 'spec_helper'

describe Seriamp::Yamaha::Cmd do
  describe '#initialize' do
    it 'works' do
      described_class.new
    end
  end

  let(:args) { [] }
  let(:stdin_c) { '' }
  let(:stdin) { StringIO.new(stdin_c) }
  let (:cmd) { described_class.new(args, stdin) }

  describe '#run' do
    describe 'no command' do
      it 'reads stdin' do
        stdin.should receive(:each_line)
        cmd.run
      end
    end

    let(:client) { double('client') }

    describe '!status' do
      let(:args) { %w(status) }

      it 'works' do
        client.should_receive(:last_status)
        Seriamp::Yamaha::Client.should receive(:new).and_return(client)
        cmd.run
      end
    end

    describe 'bulk commands' do
      describe '!status' do
        let(:stdin_c) { 'status' }

        it 'works' do
          client.should_receive(:last_status)
          Seriamp::Yamaha::Client.should receive(:new).and_return(client)
          cmd.run
        end
      end
    end
  end
end
