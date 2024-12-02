require 'spec_helper'

describe 'Yamaha replay tests' do
  fixture_path 'yamaha'

  let(:client) do
    Seriamp::Yamaha::Client.new(backend: :mock_serial_port, device: exchanges, persistent: true)
  end

  def self.client_method_test(args, fixture_name)
    method_name = args.shift
    describe "#{method_name} with #{fixture_name}" do
      let(:exchanges) { yaml_fixture(fixture_name) }

      it 'works as expected' do
        client.public_send(method_name, *args).should == eval_fixture(fixture_name)
      end
    end
  end

  client_method_test %w,status,, 'rx-v3800-status'

  client_method_test %w,all_status,, 'rx-v3800-all-status'

  client_method_test %w,parametric_eq,, 'rx-v3800-peq'

  client_method_test %w,reset_surround_left_parametric_eq,, 'rx-v3800-surround-left-peq-reset'

  client_method_test %w,reset_parametric_eq,, 'rx-v3800-peq-reset'
end
