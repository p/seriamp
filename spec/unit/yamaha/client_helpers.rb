require 'seriamp/uart'

module YamahaClientHelpers
  shared_context 'status request and response' do
    let(:status_request) do
      [:w, "001"]
    end

    let(:status_response) do
      "\x12R0212IAE@E0190002000050A9778003140500000000200F1020001002828262626262628282800020114140000A114055110000020240120000000000103002000000115077000121100A0A01FFFF0110000A0014A0014210A0A0098\x03"
    end
  end

  shared_context 'rr mock' do
    let(:extra_client_options) { {} }
    let(:client) { described_class.new(**{device: '/dev/bogus'}.update(extra_client_options)) }
    let(:device) do
      tty_double
    end

    before do
      setup_requests_responses(device, rr)
      # If argument checks fail, device won't be opened.
      mock_serial_device(device)
    end
  end
end
