require 'spec_helper'

describe 'Yamaha app integration' do
  let(:facade) do
    Seriamp::FaradayFacade.new(url: Utils.app_integration_endpoint(18990))
  end

  context 'when explicitly referencing nonexistent device path' do
    run_app 18990, 'bin/yamaha-web', '-d', '/dev/nonexistent', '--', '-p', '18990'

    context 'plain text' do
      let(:request) { facade.get('/') }

      it 'returns sensible response' do
        request.status.should == 500
        request.headers['content-type'].should == 'text/plain'
        request.body.should =~ %r,Error: Seriamp::NoDevice: Device path missing: /dev/nonexistent: Errno::ENOENT: No such file or directory.*- /dev/nonexistent,
      end
    end

    shared_examples 'json' do

      it 'returns sensible response' do
        request.status.should == 500
        request.headers['content-type'].should == 'application/json'
        JSON.parse(request.body).should == {
          'error' => 'Seriamp::NoDevice: Device path missing: /dev/nonexistent: Errno::ENOENT: No such file or directory @ rb_sysopen - /dev/nonexistent',
        }
      end
    end

    context 'json' do
      let(:request) { facade.get('/', headers: {accept: 'application/json'}) }
      include_examples 'json'
    end

    context 'current status' do
      let(:request) { facade.get('/', headers: {accept: 'application/x-seriamp-current-status'}) }
      include_examples 'json'
    end
  end
end
