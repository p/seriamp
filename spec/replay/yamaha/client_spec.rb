require 'spec_helper'

describe 'Yamaha replay tests' do
  fixture_path 'yamaha'

  describe 'status' do
    let(:client) do
      Seriamp::Yamaha::Client.new(backend: :mock_serial_port, device: exchanges)
    end

    let(:exchanges) { yaml_fixture('rx-v3800-status') }

    it 'works as expected' do
      client.status.should == eval_fixture('rx-v3800-status')
    end
  end
end
