# frozen_string_literal: true

require 'spec_helper'

describe Seriamp::Yamaha::Executor do
  let(:executor) { described_class.new(client) }

  describe '#run_command' do
    let(:client) { double('test client') }

    context 'remote-command' do
      it 'works' do
        client.should receive(:remote_command).with('7A88').and_return(42)
        executor.run_command('remote-command', '7A88').should == 42
      end
    end

    context 'remote-command-nr' do
      it 'works' do
        client.should receive(:remote_command).with('7A88', read_response: false).and_return(42)
        executor.run_command('remote-command-nr', '7A88').should == 42
      end
    end
  end
end
