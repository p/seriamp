# frozen_string_literal: true

require 'spec_helper'

class DummyClient < Seriamp::Client
  def extract_one_response
    extract_delimited_response('a')
  end
end

describe Seriamp::Client do
  let(:client) do
    DummyClient.new(timeout: 0)
  end

  describe '#extract_delimited_response' do
    context 'one delimiter' do
      subject do
        client.send(:extract_delimited_response, 'a')
      end

      context 'when there is one response in buffer' do
        before do
          client.instance_variable_set('@read_buf', +'testa')
        end

        it 'extracts the response' do
          subject.should == 'testa'
        end

        it 'does not remove response from buffer' do
          subject
          client.instance_variable_get('@read_buf').should == 'testa'
        end
      end

      context 'when there are two responses in buffer' do
        before do
          client.instance_variable_set('@read_buf', +'helloaworlda')
        end

        it 'extracts the first response' do
          subject.should == 'helloa'
        end

        it 'does not remove first response from buffer' do
          subject
          client.instance_variable_get('@read_buf').should == 'helloaworlda'
        end
      end
    end

    context 'multi-character delimiter' do
      subject do
        client.send(:extract_delimited_response, 'ab')
      end

      context 'when there are two responses in buffer' do
        before do
          client.instance_variable_set('@read_buf', +'testabtestab')
        end

        it 'extracts the first response' do
          subject.should == 'testab'
        end
      end
    end

    context 'two delimiters' do
      subject do
        client.send(:extract_delimited_response, 'a', 'b')
      end

      context 'when there is one response in buffer matching first delimiter' do
        before do
          client.instance_variable_set('@read_buf', +'testa')
        end

        it 'extracts the response' do
          subject.should == 'testa'
        end
      end

      context 'when there first response matches second delimiter' do
        before do
          client.instance_variable_set('@read_buf', +'hellobworlda')
        end

        it 'extracts the first response' do
          subject.should == 'hellob'
        end
      end
    end
  end

  describe '#extract_one_response!' do
    subject do
      client.send(:extract_one_response!)
    end

    context 'when there is one response in buffer' do
      before do
        client.instance_variable_set('@read_buf', +'testa')
      end

      it 'extracts the response' do
        subject.should == 'testa'
      end

      it 'removes response from buffer' do
        subject
        client.instance_variable_get('@read_buf').should == ''
      end
    end

    context 'when there are two responses in buffer' do
      before do
        client.instance_variable_set('@read_buf', +'helloaworlda')
      end

      it 'extracts the first response' do
        subject.should == 'helloa'
      end

      it 'removes first response from buffer' do
        subject
        client.instance_variable_get('@read_buf').should == 'worlda'
      end
    end
  end
end
