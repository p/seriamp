# frozen_string_literal: true

require 'spec_helper'

describe Seriamp::Client do
  let(:client) do
    described_class.new(timeout: 0)
  end

  describe '#extract_delimited_response' do
    context 'one delimiter' do
      subject do
        client.send(:extract_delimited_response, 'a')
      end

      context 'when there is one response in buffer' do
        before do
          client.instance_variable_set('@read_buf', 'testa')
        end

        it 'extracts the response' do
          subject.should == 'testa'
        end
      end

      context 'when there are two responses in buffer' do
        before do
          client.instance_variable_set('@read_buf', 'helloaworlda')
        end

        it 'extracts the first response' do
          subject.should == 'helloa'
        end
      end
    end

    context 'multi-character delimiter' do
      subject do
        client.send(:extract_delimited_response, 'ab')
      end

      context 'when there are two responses in buffer' do
        before do
          client.instance_variable_set('@read_buf', 'testabtestab')
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
          client.instance_variable_set('@read_buf', 'testa')
        end

        it 'extracts the response' do
          subject.should == 'testa'
        end
      end

      context 'when there first response matches second delimiter' do
        before do
          client.instance_variable_set('@read_buf', 'hellobworlda')
        end

        it 'extracts the first response' do
          subject.should == 'hellob'
        end
      end
    end
  end
end
