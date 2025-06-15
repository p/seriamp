# frozen_string_literal: true

require 'socket'
require 'spec_helper'
require 'seriamp/threaded_client'

class DummyThreadedClient < Seriamp::ThreadedClient
  MODEM_PARAMS = {
  }

  TIMEOUT = 1

  private

  def response_complete?
    read_buf.include?("\n")
  end

  def extract_one_response
    extract_delimited_response("\n")
  end

  def parse_response(resp)
    resp
  end
end

describe Seriamp::ThreadedClient do
  subject(:client) do
    DummyThreadedClient.new(timeout: 1, device: device, backend: :io, persistent: true, logger: logger)
  end

  let(:logger) { Logger.new(STDERR) }
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

  describe 'reading - internal' do
    test_timeout 3

    let(:device) { pipe_rd }

    after do
      client.close
    end

    context 'when data is already in device' do
      it 'retrieves the response' do
        pipe_wr << "test\n"
        client
        sleep 0.5

        client.responses.length.should == 1
        client.responses.shift.should == "test\n"
      end
    end

    context 'when data arrives when device is open' do
      it 'retrieves the response' do
        client
        sleep 0.5
        pipe_wr << "test\n"
        sleep 0.5

        client.responses.length.should == 1
        client.responses.shift.should == "test\n"
      end
    end
  end

  describe '#read_response' do
    let(:pipe) { Socket.pair(:UNIX, :DGRAM, 0) }

    let(:device) { pipe_rd }

    after do
      client.close
    end
  end
end
