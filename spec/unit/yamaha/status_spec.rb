# frozen_string_literal: true

require 'spec_helper'

describe Seriamp::Yamaha::Client do
  let(:client) { described_class.new }

  describe '#parse_status_response' do
    let(:parsed) { client.send(:parse_status_response, status_response) }

    context 'RX-V1500' do

      let(:status_response) do
        '1230000104343222234324324324'
      end

      it 'works' do
        parsed.should == {}
      end
    end
  end
end
