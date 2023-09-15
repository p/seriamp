# frozen_string_literal: true

module Seriamp
  module Yamaha
    module Protocol
      module Extended
        class DistanceResponse < GenericResponse
          include Yamaha::Helpers

          def initialize(cmd, value)
            super

            if value.length != 5
              raise ArgumentError, "Invalid value length: expected 5: #{value}"
            end

            @channel = CHANNEL_MAP.fetch(value[0])
            @unit = UNIT_MAP.fetch(value[1])
            case unit
            when :meters
              @distance = parse_sequence(value[2..4], '01E', 0.3, 24, 0.01)
            when :feet
              @distance = parse_sequence(value[2..4], '00A', 0, 80, 0.1)
            else
              raise NotImplementedError
            end
          end

          attr_reader :channel
          attr_reader :unit
          attr_reader :distance

          def to_s
            "#<#{self.class.name}: #{channel}: #{distance} #{unit}>"
          end

          def to_h
            {channel: channel, unit: unit, distance: distance}
          end

          def to_state
            {channel: channel, unit: unit, distance: distance}
          end

          private

          CHANNEL_MAP = {
            '0' => :center,
            '1' => :surround_back,
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

          UNIT_MAP = {
            '0' => :meters,
            '1' => :feet,
          }.freeze
        end
      end
    end
  end
end
