# frozen_string_literal: true

require 'spec_helper'
require 'seriamp/threaded_client'

class DummyClient < Seriamp::ThreadedClient
  MODEM_PARAMS = {
  }

  TIMEOUT = 1
end

describe Seriamp::ThreadedClient do
  subject(:client) do
    DummyClient.new(timeout: 1, device: device, backend: :io)
  end

  let(:pipe) { IO.pipe }
  let(:pipe_rd) { pipe[0] }
  let(:pipe_wr) { pipe[1] }
  let(:write_fd) { pipe_wr.fileno }
  let(:read_fd) { pipe_rd.fileno }

  describe 'lifecycle' do
    test_timeout 3

    let(:device) { pipe_rd }

    it 'does not raise exceptions' do
      client
      client.close
    end
  end

  describe '#do_write' do
    test_timeout 3

    let(:device) { pipe_wr }

    it 'writes' do
      client.do_write('test')
      pipe_wr.close
      pipe_rd.read.should == 'test'
    end

    after do
      client.close
    end
  end
end
