module Seriamp
  module Yamaha
    module Protocol
      module Extended
        module Constants

          private

          GRAPHIC_EQ_CHANNEL_MAP = {
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
        end
      end
    end
  end
end
