# frozen_string_literal: true

module Seriamp
  module Yamaha
    module Protocol
      module GetConstants

        private

        MAIN_INPUTS_GET = {
          '0' => 'PHONO',
          '1' => 'CD',
          '2' => 'TUNER',
          '3' => 'CD-R',
          '4' => 'MD/TAPE',
          '5' => 'DVD',
          '6' => 'DTV',
          '7' => 'CBL/SAT',
          '8' => 'SAT',
          '9' => 'VCR1',
          'A' => 'DVR/VCR2',
          'B' => 'VCR3/DVR',
          'C' => 'V-AUX/DOCK',
          'D' => 'NET/USB',
          'E' => 'XM',
        }.freeze

        AUDIO_SELECT_GET = {
          '0' => 'Auto', # Confirmed RX-V1500
          '2' => 'DTS', # Confirmed RX-V1500
          '3' => 'Coax / Opt', # Unconfirmed
          '4' => 'Analog', # Confirmed RX-V1500
          '5' => 'Analog Only', # Unconfirmed
          '8' => 'HDMI', # Unconfirmed
        }.freeze

        NIGHT_GET = {
          '0' => 'Off',
          '1' => 'Cinema',
          '2' => 'Music',
        }.freeze

        SLEEP_GET = {
          '0' => 120,
          '1' => 90,
          '2' => 60,
          '3' => 30,
          '4' => nil,
        }.freeze

        PROGRAM_GET = {
          '00' => 'Munich',
          '01' => 'Hall B',
          '02' => 'Hall C',
          '04' => 'Hall D',
          '05' => 'Vienna',
          '06' => 'Live Concert',
          '07' => 'Hall in Amsterdam',
          '08' => 'Tokyo',
          '09' => 'Freiburg',
          '0A' => 'Royaumont',
          '0B' => 'Chamber',
          '0C' => 'Village Gate',
          '0D' => 'Village Vanguard',
          '0E' => 'The Bottom Line',
          '0F' => 'Cellar Club',
          '10' => 'The Roxy Theater',
          '11' => 'Warehouse Loft',
          '12' => 'Arena',
          '14' => 'Disco',
          '15' => 'Party',
          '17' => '7ch Stereo',
          '18' => 'Music Video',
          '19' => 'DJ',
          '1C' => 'Recital/Opera',
          '1D' => 'Pavilion',
          '1E' => 'Action Gamae',
          '1F' => 'Role Playing Game',
          '20' => 'Mono Movie',
          '21' => 'Sports',
          '24' => 'Spectacle',
          '25' => 'Sci-Fi',
          '28' => 'Adventure',
          '29' => 'Drama',
          '2C' => 'Surround Decode',
          '2D' => 'Standard',
          '30' => 'PLII Movie',
          '31' => 'PLII Music',
          '32' => 'Neo:6 Movie',
          '33' => 'Neo:6 Music',
          '34' => '2ch Stereo',
          '35' => 'Direct Stereo',
          '36' => 'THX Cinema',
          '37' => 'THX Music',
          '3C' => 'THX Game',
          '40' => 'Enhancer 2ch Low',
          '41' => 'Enhancer 2ch High',
          '42' => 'Enhancer 7ch Low',
          '43' => 'Enhancer 7ch High',
          '80' => 'Straight',
        }.freeze

        POWER_GET = {
          '00' => {main_power: false, zone2_power: false, zone3_power: false},
          '01' => {main_power: true, zone2_power: true, zone3_power: true},
          '02' => {main_power: true, zone2_power: false, zone3_power: false},
          '03' => {main_power: false, zone2_power: true, zone3_power: true},
          '04' => {main_power: true, zone2_power: true, zone3_power: false},
          '05' => {main_power: true, zone2_power: false, zone3_power: false},
          '06' => {main_power: false, zone2_power: true, zone3_power: true},
          '07' => {main_power: false, zone2_power: false, zone3_power: true},
        }.freeze
      end
    end
  end
end
