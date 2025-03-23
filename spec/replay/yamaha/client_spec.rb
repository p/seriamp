require 'spec_helper'

describe 'Yamaha replay tests' do
  fixture_path 'yamaha'

  let(:base_options) do
    {
      backend: :logging_mock_serial_port,
      device: Seriamp::Backend::MockSerialPortBackend::Exchanges.new(exchanges),
      persistent: true,
    }
  end

  let(:client_options) do
    {}
  end

  let(:client) do
    Seriamp::Yamaha::Client.new(**base_options.merge(client_options))
  end

  def self.client_method_test(args, fixture_name)
    with_fixture(fixture_name) do
      args = args.dup
      method_name = args.shift
      describe method_name do
        it 'returns expected value' do
          client.public_send(method_name, *args).should == eval_fixture(fixture_name)
        end

        if status_fixture?(fixture_name)
          it 'produces expected state' do
            client.public_send(method_name, *args)
            client.current_status.should == status_fixture(fixture_name)
          end
        end
      end
    end
  end

  def self.with_fixture(fixture_name, &block)
  #require'byebug';byebug
    context "with #{fixture_name}" do
      let(:exchanges) do
        yaml_fixture(fixture_name)
      end

      instance_exec(&block)
    end
  end

  client_method_test %w,status,, 'rx-v3800-status'

  # Extra response prior to proper status response
  client_method_test %w,status,, 'rx-v3800-status-pre'

  client_method_test %w,all_status,, 'rx-v3800-all-status'

  client_method_test %w,parametric_eq,, 'rx-v3800-peq'

  client_method_test %w,reset_surround_left_parametric_eq,, 'rx-v3800-surround-left-peq-reset'

  client_method_test %w,reset_parametric_eq,, 'rx-v3800-peq-reset'

  # Extra response prior to proper command response when there is existing state
  client_method_test ['set_pure_direct', true], 'rx-v3800-command-pre-with-state'

  context 'without retries' do
    let(:client_options) do
      {retries: false}
    end

    # status when off
    with_fixture 'rx-v1700-off-status' do
      describe 'status' do
        it 'raises CommunicationTimeout' do
          lambda do
            client.status
          end.should raise_error(Seriamp::CommunicationTimeout)
        end
      end
    end
  end

  context 'with retries' do
    let(:client_options) do
      {retries: true}
    end

    # status when off
    client_method_test %w,status,, 'rx-v1700-off-status'

    client_method_test ['set_pure_direct', true], 'command-retry'
  end

  def self.multi_test(commands, fixture_name)
    with_fixture(fixture_name) do
      describe fixture_name do
        let(:fixture) do
          eval_fixture(fixture_name)
        end

        it 'returns expected value' do
          commands.each_with_index do |args, index|
            args = args.dup
            method_name = args.shift
            client.public_send(method_name, *args).should == fixture[index]
          end
        end

        if status_fixture?(fixture_name)
          it 'produces expected state' do
            commands.each_with_index do |args, index|
              args = args.dup
              method_name = args.shift
              client.public_send(method_name, *args)
            end

            client.current_status.should == status_fixture(fixture_name)
          end
        end
      end
    end
  end

  multi_test [%w,status,, %w,status,,], 'power-true-then-false'
end
