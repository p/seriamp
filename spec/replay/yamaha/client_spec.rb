require 'spec_helper'

describe 'Yamaha replay tests' do
  fixture_path 'yamaha'

  let(:client) do
    Seriamp::Yamaha::Client.new(backend: :mock_serial_port, device: exchanges, persistent: true)
  end

  def self.client_method_test(method_name, fixture_name)
    describe "#{method_name} with #{fixture_name}" do
      let(:exchanges) { yaml_fixture(fixture_name) }

      it 'works as expected' do
        client.public_send(method_name).should == eval_fixture(fixture_name)
      end
    end
  end

  client_method_test 'status', 'rx-v3800-status'

  client_method_test 'all_status', 'rx-v3800-all-status'
end
