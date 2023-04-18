# frozen_string_literal: true

module Seriamp
  module Yamaha
    module Protocol
      module Status

        private

        STATUS_FIELDS_R0178 = [
          [nil, nil, 'Baud rate (@)'],
          [nil, nil, 'Receive buffer (E)'],
          [nil, nil, 'Receive buffer (0)'],
          [nil, nil, 'Command timeout (1)'],
          [nil, nil, 'Command timeout (9)'],
          [nil, nil, 'Command timeout (0)'],
          [nil, nil, 'Handshaking (0)'],

          [:busy, :off_on, 'System busy status'],
          [:power, :off_on, 'System power'],
          [:input, nil, 'Main zone input'],
          [:multi_ch_input, :off_on, 'Input is multi-channel input'],
          [:input_mode, nil, 'Input mode'],
          [:mute, :off_on, 'Main zone mute'],
        ].freeze

        STATUS_FIELDS_R0226 = (STATUS_FIELDS_R0178[..6] + [
        ]).freeze

        STATUS_FIELDS_MAP = {
          'R0178' => STATUS_FIELDS_R0178,
          'R0226' => STATUS_FIELDS_R0226,
        ].freeze
      end
    end
  end
end
