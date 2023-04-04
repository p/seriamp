module Seriamp
  module Yamaha
    module Protocol
      module Extended
        class GraphicEqResponse < GenericResponse
          include Yamaha::Helpers

          def initialize(cmd, value)
            super

            if value.length != 4
              raise ArgumentError, "Invalid value length: expected 4: #{value}"
            end

            @channel = CHANNEL_MAP.fetch(value[0])
            band_map = CHANNEL_BAND_MAP.fetch(channel)
            @frequency = band_map.fetch(value[1])
            @gain = parse_volume(value[2..3], '03', -6, 6, 0.5)
          end

          attr_reader :channel
          attr_reader :frequency
          attr_reader :gain

          def to_s
            "#<#{self.class.name}: #{channel} freq=#{frequency} gain=#{gain}>"
          end

          private

          CHANNEL_MAP = {
            '0' => :center,
            '1' => :surround_back, # single
            '2' => :front_left,
            '3' => :front_right,
            '4' => :surround_left,
            '5' => :surround_right,
            '6' => :surround_back_left,
            '7' => :surround_back_right,
            '8' => :presence_left,
            '9' => :presence_right,
            'A' => :subwoofer,
          }.freeze

          BAND_MAP = {
            '0' => 63,
            '2' => 160,
            '4' => 400,
            '6' => 1000,
            '8' => 2500,
            'A' => 6300,
            'C' => 16000,
          }.freeze

          SUBWOOFER_BAND_MAP = {
            '0' => 63,
            '2' => 160,
          }.freeze

          CHANNEL_BAND_MAP = {
            center: BAND_MAP,
            surround_back: BAND_MAP,
            front_left: BAND_MAP,
            front_right: BAND_MAP,
            surround_left: BAND_MAP,
            surround_right: BAND_MAP,
            surround_back_left: BAND_MAP,
            surround_back_right: BAND_MAP,
            presence_left: BAND_MAP,
            presence_right: BAND_MAP,
            subwoofer: SUBWOOFER_BAND_MAP,
          }.freeze
        end
      end
    end
  end
end
