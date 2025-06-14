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

  describe '#do_write' do
    let(:device) { pipe_wr }

    test_timeout 1

    it 'writes' do
      client.do_write('test')
      pipe_wr.close
      pipe_rd.read.should == 'test'
    end
  end
end
