require 'spec_helper'

describe 'Yamaha app integration' do
  let(:facade) do
    Seriamp::FaradayFacade.new(url: Utils.app_integration_endpoint(18990))
  end

  context 'when explicitly referencing nonexistent device path' do
    run_app 18990, 'bin/yamaha-web', '-d', '/dev/nonexistent', '--', '-p', '18990'

    let(:request) { facade.get('/') }

    it 'returns sensible' do
      request.status.should == 200
      request.headers['content-type'].should == 'application/json'
    end
  end
end
