# frozen_string_literal: true

module Seriamp
  module Yamaha
    module Protocol
      module Extended
        module Constants

          private

          GRAPHIC_EQ_CHANNEL_MAP = {
            '0' => :center,
            #'1' => :surround_back, # single? does not work
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

          GRAPHIC_EQ_BAND_MAP = {
            '0' => 63,
            '2' => 160,
            '4' => 400,
            '6' => 1000,
            '8' => 2500,
            'A' => 6300,
            'C' => 16000,
          }.freeze

          GRAPHIC_EQ_SUBWOOFER_BAND_MAP = {
            '0' => 63,
            '2' => 160,
          }.freeze

          GRAPHIC_EQ_CHANNEL_BAND_MAP = {
            center: GRAPHIC_EQ_BAND_MAP,
            surround_back: GRAPHIC_EQ_BAND_MAP,
            front_left: GRAPHIC_EQ_BAND_MAP,
            front_right: GRAPHIC_EQ_BAND_MAP,
            surround_left: GRAPHIC_EQ_BAND_MAP,
            surround_right: GRAPHIC_EQ_BAND_MAP,
            surround_back_left: GRAPHIC_EQ_BAND_MAP,
            surround_back_right: GRAPHIC_EQ_BAND_MAP,
            presence_left: GRAPHIC_EQ_BAND_MAP,
            presence_right: GRAPHIC_EQ_BAND_MAP,
            subwoofer: GRAPHIC_EQ_SUBWOOFER_BAND_MAP,
          }.freeze

          # RX-V3800
          PARAMETRIC_EQ_LOW_FREQS = [
            31.3, 39.4, 49.6, 52.5, 78.7, 99.2, 125, 157.5,
          ].freeze

          PARAMETRIC_EQ_LOW_FREQS_INTEGER = PARAMETRIC_EQ_LOW_FREQS.map do |f|
            f.round.to_i
          end.freeze

          # RX-V3800
          PARAMETRIC_EQ_MID_FREQS = [
            198.4, 250, 315, 396.9, 500, 630, 793.7, 1000, 1260, 1590,
            2000, 2520, 3170, 4000, 5040, 6350, 8000, 10100, 12700, 16000,
          ].freeze

          PARAMETRIC_EQ_MID_FREQS_INTEGER = PARAMETRIC_EQ_MID_FREQS.map do |f|
            f.round.to_i
          end.freeze

          PARAMETRIC_EQ_MAP = {
            '06' => 31.3,
            '08' => 39.4,
            '0A' => 49.6,
            '0C' => 62.5,
            '0E' => 78.7,
            '10' => 99.2,
            '12' => 125.0,
            '14' => 157.7,
            '16' => 198.4,
            '18' => 250.0,
            '1A' => 315.0,
            '1C' => 396.9,
            '1E' => 500.0,
            '20' => 630.0,
            '22' => 793.7,
            '24' => 1000.0,
            '26' => 1260.0,
            '28' => 1590.0,
            '2A' => 2000.0,
            '2C' => 2520.0,
            '2E' => 3170.0,
            '30' => 4000.0,
            '32' => 5040.0,
            '34' => 6350.0,
            '36' => 8000.0,
            '38' => 10100.0,
            '3A' => 12700.0,
            '3C' => 16000.0,
          }.freeze

          DEFAULT_PARAMETRIC_EQ_FREQUENCIES = [
            # RX-V3800
            62.5, 157.7, 396.9, 1000, 2520, 6350, 16000,
          ].freeze

          PARAMETRIC_EQ_Q_MAP = {
            '0' => 0.5,
            '1' => 0.63,
            '2' => 0.794,
            '3' => 1.0,
            '4' => 1.26,
            '5' => 1.587,
            '6' => 2.0,
            '7' => 2.52,
            '8' => 3.175,
            '9' => 4.0,
            'A' => 5.04,
            'B' => 6.35,
            'C' => 8.0,
            'D' => 10.8,
          }.freeze
        end
      end
    end
  end
end
