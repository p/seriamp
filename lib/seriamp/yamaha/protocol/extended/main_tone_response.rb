module Seriamp
  module Yamaha
    module Protocol
      module Extended
        class MainToneResponse < GenericResponse
          def initialize(cmd, value)
            super

            if value.length != 5
              raise ArgumentError, "Invalid value length: expected 5: #{value}"
            end

            @output = OUTPUT_MAP.fetch(value[0])
            @tone = TONE_MAP.fetch(value[1])
            @turn_over_frequency = TURN_OVER_MAP.fetch(@tone).fetch(value[2])
            @gain = value[3..4]
          end

          private

          OUTPUT_MAP = {
            '0' => :speaker,
            '1' => :headphone,
          }.freeze

          TONE_MAP = {
            '0' => :bass,
            '1' => :treble,
          }.freeze

          BASS_TURN_OVER_MAP = {
            '0' => 125,
            '1' => 350,
            '2' => 500,
          }.freeze

          TREBLE_TURN_OVER_MAP = {
            '0' => 2500,
            '1' => 3500,
            '2' => 8000,
          }.freeze

          TURN_OVER_MAP = {
            bass: BASS_TURN_OVER_MAP,
            treble: TREBLE_TURN_OVER_MAP,
          }.freeze
        end
      end
    end
  end
end
