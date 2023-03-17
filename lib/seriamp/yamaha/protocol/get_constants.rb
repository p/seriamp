# frozen_string_literal: true

module Seriamp
  module Yamaha
    module Protocol
      module GetConstants

        private

        STATUS_HEAD_FIELDS = [
          'DC2',
          'Model',
          'Model',
          'Model',
          'Model',
          'Model',
          'FW Version',
          'Data length',
          'Data length',
        ]

        STATUS_FIELDS = [
          'Baud rate',
          'Receive buffer',
          'Receive buffer',
          'Command timeout',
          'Command timeout',
          'Handshaking',
          'Busy flag',
          'Power boolean',
          'Input',
          'Multi-channel input',
          'Input mode',
          'Mute',
          'Zone 2 input',
          'Zone 2 mute',
          'Master volume',
          'Master volume',
          'Zone 2 volume',
          'Zone 2 volume',
          'Program',
          'Program',
          'Effect',
          '6.1/ES key status',
          'OSD',
          'Sleep timer',
          'Tuner page',
          'Tuner number',
          'Night mode',
          'N/A',
          'Speaker A',
          'Speaker B',
          'Playback',
          'Sample rate',
          'EX/ES playback',
          'Thr / bypass',
          'RED DTS',
          'Headphones',
          'Tuner band',
          'Tuner tuned',
          'DC1 control out',
          'N/A',
          'N/A',
          'DC1 trigger control',
          'DTS 96/24',
        ]

        STATUS_TAIL_FIELDS = [
          'Checksum',
          'Checksum',
        ]

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

        DECODER_MODE_GET = {
          '0' => 'Auto',
          '1' => 'DTS',
          '2' => 'AAC',
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

        FORMAT_GET = {
          '00' => 'Analog',
          '01' => 'PCM',
          '02' => 'DSD',
          '03' => 'Digital',
          '04' => 'Dolby Digital',
          '05' => 'DTS',
          '06' => 'AAC',
          '07' => 'DTS-HD',
          '08' => 'DTS-HD MSTR',
          '09' => 'DD Plus',
          '0A' => 'TrueHD',
          '0B' => 'WMA',
          '0C' => 'MP3',
          'FE' => '???',
          'FF' => '---',
        }.freeze

        SAMPLING_GET = {
          '00' => 'Analog',
          '01' => '8000',
          '02' => '11025',
          '03' => '12000',
          '04' => '16000',
          '05' => '22050',
          '06' => '24000',
          '07' => '32000',
          '08' => '44100',
          '09' => '48000',
          '0A' => '64000',
          '0B' => '88200',
          '0C' => '96000',
          '0D' => '128000',
          '0E' => '176400',
          'OF' => '192000',
          '10' => 'DSD', # 2.8224 MHz
          'FE' => '???',
          'FF' => '---',
        }.freeze

        INPUT_CHANNELS_GET = {
          '00' => '1+',
          '01' => '1/0',
          '02' => '2/0',
          '03' => '3/0',
          '04' => '2/1',
          '05' => '3/1',
          '06' => '2/2',
          '07' => '3/2',
          '08' => '2/3',
          '09' => '3/3',
          '0A' => '2/4',
          '0B' => '3/4',
          'AC' => 'MLT',
          '0F' => '---',
        }.freeze

        INPUT_LFE_CHANNEL_GET = {
          '00' => '0.1',
          'FF' => '---',
        }.freeze

        BIT_RATE_GET = {
          '00' => '32000',
          '01' => '40000',
          '02' => '48000',
          '03' => '56000',
          '04' => '64000',
          '05' => '72000',
          '06' => '80000',
          '07' => '96000',
          '08' => '112000',
          '09' => '128000',
          '0A' => '144000',
          '0B' => '160000',
          '0C' => '192000',
          '0D' => '224000',
          '0E' => '256000',
          '0F' => '288000',
          '10' => '320000',
          '11' => '384000',
          '12' => '448000',
          '13' => '512000',
          '14' => '576000',
          '15' => '640000',
          '16' => '768000',
          '17' => '960000',
          '18' => '1024000',
          '19' => '1152000',
          '1A' => '1280000',
          '1B' => '1344000',
          '1C' => '1408000',
          '1D' => '1411200',
          '1E' => '1472000',
          '1F' => '1536000',
          '20' => '1920000',
          '21' => '2048000',
          '22' => '3072000',
          '23' => '3840000',
          '24' => 'Open',
          '25' => 'Variable',
          '26' => 'Losless',
          'FF' => '---',
        }.freeze

        POWER_GET = {
          '00' => {main_power: false, zone2_power: false, zone3_power: false}.freeze,
          '01' => {main_power: true, zone2_power: true, zone3_power: true}.freeze,
          '02' => {main_power: true, zone2_power: false, zone3_power: false}.freeze,
          '03' => {main_power: false, zone2_power: true, zone3_power: true}.freeze,
          '04' => {main_power: true, zone2_power: true, zone3_power: false}.freeze,
          '05' => {main_power: true, zone2_power: false, zone3_power: false}.freeze,
          '06' => {main_power: false, zone2_power: true, zone3_power: true}.freeze,
          '07' => {main_power: false, zone2_power: false, zone3_power: true}.freeze,
        }.freeze

        INPUT_NAME_GET = {
          '00' => 'PHONO',
          '01' => 'CD',
          '02' => 'TUNER',
          '03' => 'CD-R',
          '04' => 'MD/TAPE',
          '05' => 'DVD',
          '06' => 'DTV',
          '07' => 'CBL/SAT',
          '08' => 'SAT',
          '09' => 'VCR1',
          '0A' => 'DVR/VCR2',
          '0B' => 'VCR3/DVR',
          '0C' => 'V-AUX/DOCK',
          '0D' => 'NET/USB',
          '0E' => 'XM',
          '10' => 'Multi-Channel',
        }.freeze

        MUTE_GET = {
          '00' => false,
          '01' => true,
        }.freeze

        GET_MAP = {
          '10' => :format,
          '11' => :sampling,
          '12' => :input_channels,
          '13' => :input_lfe_channel,
          '14' => :bit_rate,
          '20' => :power,
          '21' => :input_name,
          '23' => :mute,
        }.freeze
      end
    end
  end
end
