# frozen_string_literal: true

module Seriamp
  module Yamaha
    module Constants

      MODEL_NAMES = {
        # RX-V1000
        # RX-V3000
        # RX-V2200
        'R0112' => 'RX-V3200',
        'R0114' => 'RX-Z1',
        'R0132' => 'RX-V2300',
        'R0133' => 'RX-V3300',
        # Documentation for both RX-V2400 and RX-Z9 claims they identify as R0161
        'R0161' => 'RX-V2400/RX-Z9',
        # RX-V1500 and HTR-5890 both identify themselves as R0177
        'R0177' => 'RX-V1500/HTR-5890',
        'R0178' => 'RX-V2500',
        'R0190' => 'RX-V4600',
        'R0191' => 'RX-V1600',
        'R0193' => 'RX-V2600',
        # HTR-5990
        'R0210' => 'RX-V1700',
        'R0212' => 'RX-V2700',
        'R0225' => 'RX-V3800',
        'R0226' => 'RX-V1800',
        'R0227' => 'HTR-6190',
        'R0240' => 'RX-V1900',
        'R0241' => 'HTR-6290',
        # RX-V3900 does not implement the "yamaha" protocol
        'R0258' => 'RX-V2065',
        'R0259' => 'HTR-6290',
        # RX-V1067
        # RX-V2067
        # RX-V3067
      }.freeze

      MODEL_IDS = MODEL_NAMES.invert.freeze
    end
  end
end
