require 'spec_helper'

describe 'Yamaha tcp backend integration' do
  run_app 18990, 'bin/yamaha-web', '-d', '/dev/nonexistent', '--', '-p', '18990'

  let(:client) do
    Seriamp::Yamaha::Client.new(device: 'localhost:18990', backend: 'tcp')
  end

  context 'current status' do
    it 'works' do
      p client.status
    end
  end
end
