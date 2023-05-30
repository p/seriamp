# frozen_string_literal: true

module Seriamp
  module Yamaha
    module Protocol
      module GetConstants

        private

        def self.prefix_keys_with_zero(table)
          Hash[table.map do |k, v|
            ['0' + k, v]
          end].freeze
        end

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

        __UNUSED__STATUS_FIELDS = [
          'Baud rate (@)',
          'Receive buffer (E)',
          'Receive buffer (0)',
          'Command timeout (1)',
          'Command timeout (9)',
          'Command timeout (0)',
          'Handshaking (0)',
        ]

        STATUS_TAIL_FIELDS = [
          'Checksum',
          'Checksum',
          'ETX',
        ]

        BUSY_STANDBY_GET = {
          '0' => 'OK',
          '1' => 'Busy',
          '2' => 'Standby',
        }

        # RX-V1 and RX-V3200 need a different table.
        INPUT_NAME_1_GET = {
          '0' => 'PHONO',
          '1' => 'CD',
          '2' => 'TUNER',
          '3' => 'CD-R',
          '4' => 'MD/TAPE',
          '5' => 'DVD',
          # "LD" was removed from input 6 as of RX-V2500/RX-V1600.
          '6' => 'DTV/LD',
          '7' => 'CBL/SAT',
          # Input 8 is not used as of RX-V1300 or earlier.
          '8' => 'SAT',
          '9' => 'VCR1',
          'A' => 'DVR/VCR2',
          'B' => 'VCR3/DVR',
          'C' => 'V-AUX/DOCK',
          'D' => 'NET/USB',
          'E' => 'XM',
        }.freeze

        INPUT_NAME_1_1800_GET = {
          '0' => 'PHONO',
          '1' => 'CD',
          '2' => 'TUNER',
          '3' => 'CD-R',
          '4' => 'MD/TAPE',
          '5' => 'DVD',
          '6' => 'DTV/CBL',
          '9' => 'VCR',
          'A' => 'DVR',
          'C' => 'V-AUX',
          'D' => 'NET/USB',
          'E' => 'XM',
          'F' => 'BD/HD DVD',
        }.freeze

        INPUT_NAME_2_GET = {
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

        DECODER_MODE_SETTING_GET = {
          '0' => 'Auto',
          '1' => 'Last',
        }.freeze

        AUDIO_SELECT_SETTING_GET = DECODER_MODE_SETTING_GET

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

        NIGHT_MODE_GET = {
          '0' => 'Off',
          '1' => 'Cinema',
          '2' => 'Music',
        }.freeze

        NIGHT_MODE_PARAMETER_GET = {
          '0' => 'Low',
          '1' => 'Middle',
          '2' => 'High',
        }.freeze

        SLEEP_GET = {
          '0' => 120,
          '1' => 90,
          '2' => 60,
          '3' => 30,
          '4' => nil,
        }.freeze

        SLEEP_1500_GET = {
          '0' => 120,
          '2' => 90,
          '3' => 60,
          '4' => 30,
          '5' => nil,
        }.freeze

        PLAYBACK_MODE_GET = {
          '0' => '6ch Input',
          '1' => 'Analog',
          '2' => 'PCM',
          '3' => 'DD except 2.0',
          '4' => 'DD 2.0',
          '5' => 'DD Karaoke',
          '6' => 'DD EX',
          '7' => 'DTS',
          '8' => 'DTS-ES',
          '9' => 'Other Digital',
          'A' => 'DTS Analog Mute',
          'B' => 'DTS ES Discrete',
        }.freeze

        TUNER_PAGE_GET = {
          '0' => 'A',
          '1' => 'B',
          '2' => 'C',
          '3' => 'D',
          '4' => 'E',
        }.freeze

        TUNER_NUMBER_GET = {
          '0' => 1,
          '1' => 2,
          '2' => 3,
          '3' => 4,
          '4' => 5,
          '5' => 6,
          '6' => 7,
          '7' => 8,
        }.freeze

        TUNER_BAND_GET = {
          '0' => 'FM',
          '1' => 'AM',
        }.freeze

        XM_SEARCH_MODE_GET = {
          '0' => 'All',
          '1' => 'Category',
          '2' => 'Preset',
        }.freeze

        XM_CHANNEL_NUMBER_GET = Hash[(0..255).map { |i| [i, '%02X' % i ] }].invert.freeze

        TUNER_SETUP_GET = {
          '0' => 'AM10/FM100',
          '1' => 'AM9/FM0',
        }.freeze

        PROGRAM_NAME_GET = {
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

        INPUT_MODE_GET = {
          '0' => 'Auto',
          '2' => 'DTS',
          '4' => 'Analog',
          '5' => 'Analog Only',
        }.freeze

        INPUT_MODE_SETTING_GET = {
          '0' => 'Auto',
          '1' => 'Last',
        }.freeze

        SAMPLE_RATE_1_GET = {
          '0' => 'Analog',
          '1' => '32000',
          '2' => '44100',
          '3' => '48000',
          '4' => '64000',
          '5' => '88200',
          '6' => '96000',
          '7' => 'Unknown',
        }.freeze

        SAMPLE_RATE_2_GET = {
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

        CHANNEL_INDICATOR_GET = {
          '0' => '1+',
          '1' => '1/0',
          '2' => '2/0',
          '3' => '3/0',
          '4' => '2/1',
          '5' => '3/1',
          '6' => '2/2',
          '7' => '3/2',
          '8' => '2/3',
          '9' => '3/3',
          'A' => '2/4',
          'B' => '3/4',
          'C' => 'MLT',
          'F' => '---',
        }.freeze

        CHANNEL_INDICATOR_REPORT_GET = prefix_keys_with_zero(CHANNEL_INDICATOR_GET)

        LFE_INDICATOR_GET = {
          '0' => '0.1',
          'F' => '---',
        }.freeze

        LFE_INDICATOR_REPORT_GET = {
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

        DUAL_MONO_OUT_GET = {
          '0' => 'Main',
          '1' => 'Subwoofer',
          '2' => 'All',
        }.freeze

        TRIGGER_CONTROL_1500_GET = {
          '0' => 'Zone1',
          '1' => 'Zone2',
          '2' => 'Zone1 & Zone2',
          # Undocumented value.
          '3' => '???',
        }.freeze

        TRIGGER_CONTROL_GET = {
          '0' => 'All',
          '1' => 'Main',
          '2' => 'Zone2',
          '3' => 'Zone3',
        }.freeze

        SPEAKER_OUT_GET = {
          '0' => 'Ext',
          '1' => 'Int Speaker 1',
          '2' => 'Int Speaker 2',
          '3' => 'Int Both',
        }.freeze

        SPEAKER_B_ZONE_GET = {
          '0' => 'Zone1',
          '1' => 'Zone2',
        }.freeze

        POWER_GET = {
          '0' => {main_power: false, zone2_power: false, zone3_power: false}.freeze,
          '1' => {main_power: true, zone2_power: true, zone3_power: true}.freeze,
          '2' => {main_power: true, zone2_power: false, zone3_power: false}.freeze,
          '3' => {main_power: false, zone2_power: true, zone3_power: true}.freeze,
          '4' => {main_power: true, zone2_power: true, zone3_power: false}.freeze,
          '5' => {main_power: true, zone2_power: false, zone3_power: false}.freeze,
          '6' => {main_power: false, zone2_power: true, zone3_power: true}.freeze,
          '7' => {main_power: false, zone2_power: false, zone3_power: true}.freeze,
        }.freeze

        POWER_REPORT_GET = prefix_keys_with_zero(POWER_GET)

        MUTE_GET = {
          '00' => false,
          '01' => true,
        }.freeze

        XM_MESSAGE_GET = {
          '00' => 'Check Antenna',
          '01' => 'Updating',
          '02' => 'No Signal',
          '03' => 'Loading',
          '04' => 'Off Air',
          '05' => 'Unavailable',
        }.freeze

        OFF_ON_GET = {
          '00' => false,
          '01' => true,
        }.freeze

        ES_KEY_1500_GET = {
          '0' => 'Off',
          '1' => 'Matrix On',
          '2' => 'Discrete On',
          '3' => 'Auto',
        }.freeze

        ES_STATUS_GET = {
          '0' => 'Off',
          '1' => 'Matrix On',
          '2' => 'Discrete On',
        }.freeze

        ES_KEY_GET = {
          '0' => 'Off',
          '1' => 'EX/ES',
          '3' => 'Auto',
          '4' => 'EX',
          '5' => 'PLIIx Movie',
          '6' => 'PLIIx Music',
        }.freeze

        OSD_MESSAGE_GET = {
          # Not used as of RX-V2700 or earlier
          '0' => 'Full',
          '1' => 'Short',
          '2' => 'Off',
        }.freeze

        ZONE_OSD_GET = {
          '0' => 'Off',
          '1' => 'Zone2',
          '2' => 'Zone2 & Zone3',
        }.freeze

        ON_SCREEN_GET = {
          '1' => '10',
          '2' => '30',
          '3' => 'Always',
        }.freeze

        DIMMER_GET = {
          '0' => -4,
          '1' => -3,
          '2' => -2,
          '3' => -1,
          '4' => 0,
        }.freeze

        DYNAMIC_RANGE_GET = {
          '0' => 'Max',
          '1' => 'Std',
          '2' => 'Min',
        }.freeze

        VOLUME_OUT_GET = {
          '0' => 'Variable',
          '1' => 'Fixed',
        }.freeze

        SPEAKER_SETTING_GET = {
          '0' => 'Large',
          '1' => 'Small',
          '2' => 'None',
        }.freeze

        BASS_OUT_GET = {
          '0' => 'Subwoofer',
          '1' => 'Front',
          '2' => 'Both',
        }.freeze

        SUBWOOFER_PHASE_GET = {
          '0' => 'Normal',
          '1' => 'Reverse',
        }.freeze

        EQ_SELECT_GET = {
          '0' => 'Auto PEQ',
          '1' => 'GEQ',
          '2' => 'Off',
        }.freeze

        WALLPAPER_GET = {
          '0' => 'Yes',
          'E' => 'Gray',
          'F' => 'None',
        }.freeze

        GUI_LANGUAGE_GET = {
          '0' => 'English',
          '1' => 'Japanese',
          '2' => 'French',
          '3' => 'German',
          '4' => 'Spanish',
          '5' => 'Russian',
        }.freeze

        HDMI_UPSCALING_GET = {
          '0' => 'Through',
          '1' => '480p (576p)',
          '2' => '1080i',
          '3' => '720p',
          '4' => '1080p', # As of RX-V1800
        }.freeze

        HDMI_ASPECT_GET = {
          '0' => 'Through',
          '1' => '16:9 Normal',
          '2' => 'Smart Zoom',
        }.freeze

        SB_SPEAKER_SETTING_GET = {
          '0' => 'Large x2',
          '1' => 'Large x1',
          '2' => 'Small x2',
          '3' => 'Small x1',
          '4' => 'None',
        }.freeze

        DECODER_SELECT_GET = {
          '0' => 'Pro Logic',
          '1' => 'PLIIx Movie',
          '2' => 'PLIIx Music',
          '3' => 'PLIIx Game',
          '4' => 'Neo:6 Cinema',
          '5' => 'Neo:6 Music',
          '6' => 'CSII Cinema',
          '7' => 'CSII Music',
          '9' => 'Neural Surround',
        }.freeze

        REMOTE_ID_GET = {
          '0' => 'ID1',
          '1' => 'ID2',
        }.freeze

        SPEAKER_IMPEDANCE_GET = {
          '0' => 8,
          '1' => 6,
        }.freeze

        MULTI_CH_SELECT_GET = {
          '0' => '6ch',
          '2' => '8ch CD',
          '3' => '8ch CD-R',
          '4' => '8ch MD/TAPE',
          '5' => '8ch DVD',
          '6' => '8ch DTV',
          '7' => '8ch CBL/SAT',
          '9' => '8ch VCR1',
          'A' => '8ch DVR/VCR2',
          'C' => '8ch V-AUX',
        }.freeze

        MULTI_CH_SELECT_1800_GET = {
          '0' => '6ch',
          '2' => '8ch CD',
          '3' => '8ch CD-R',
          '4' => '8ch MD/TAPE',
          '5' => '8ch DVD',
          '6' => '8ch DTV/CBL',
          '9' => '8ch VCR',
          'A' => '8ch DVR',
          'C' => '8ch V-AUX',
          'F' => '8ch BD/HD DVD',
        }.freeze

        REMOTE_ID_XM_GET = {
          '0' => 'ID1',
          '1' => 'ID2',
        }.freeze

        SUBWOOFER_CROSSOVER_GET = {
          '0' => 40,
          '1' => 60,
          '2' => 80,
          '3' => 90,
          '4' => 100,
          '5' => 110,
          '6' => 120,
          '7' => 160,
          '8' => 200,
        }.freeze

        TV_FORMAT_GET = {
          '0' => 'PAL',
          '1' => 'NTSC',
        }.freeze

        PRESENCE_SURROUND_BACK_SELECT_GET = {
          '0' => 'Presence',
          '1' => 'Surround Back',
        }.freeze

        FL_SCROLL_GET = {
          '0' => 'Continue',
          '1' => 'Once',
        }.freeze

        MULTI_CH_BGV_GET = {
          '0' => 'Off',
          '1' => 'Last',
          '5' => 'DVD',
          '6' => 'DTV',
          '7' => 'CBL/SAT',
          '9' => 'VCR1',
          'A' => 'DVR/VCR2',
          'C' => 'V-AUX',
        }.freeze

        MULTI_CH_BGV_1800_GET = {
          '0' => 'Off',
          '1' => 'Last',
          '5' => 'DVD',
          '6' => 'DTV/CBL',
          '9' => 'VCR',
          'A' => 'DVR',
          'C' => 'V-AUX',
          'F' => 'BD/HD DVD',
        }.freeze

        IPOD_REPEAT_GET = {
          '0' => 'Off',
          '1' => 'One',
          '2' => 'All',
        }.freeze

        IPOD_SHUFFLE_GET = {
          '0' => 'Off',
          '1' => 'Songs',
          '2' => 'Albums',
        }.freeze

        NET_USB_REPEAT_GET = {
          '0' => 'Off',
          '1' => 'Single',
          '2' => 'All',
        }.freeze

        NET_USB_SOURCE_GET = {
          '0' => 'PC/MCX',
          '1' => 'Net Radio',
          '2' => 'USB',
        }.freeze

        # RX-V1500 only goes to 160 ms
        AUDIO_DELAY_GET = Hash[(0..240).map { |i| [i, '%02X' % i ] }].invert.freeze

        SPEAKER_A_GET = OFF_ON_GET

        SPEAKER_B_GET = OFF_ON_GET

        TEST_GET = OFF_ON_GET

        PURE_DIRECT_GET = OFF_ON_GET

        GET_MAP = {
          '06' => :xm_message,
          '10' => :format,
          '11' => [:sample_rate, :sample_rate_2],
          '12' => [:channel_indicator, :channel_indicator_report],
          '13' => [:lfe_indicator, :lfe_indicator_report],
          '14' => :bit_rate,
          '20' => [:power, :power_report],
          '21' => [:input_name, :input_name_2],
          '23' => :mute,
          '28' => :program_name,
          '2E' => :speaker_a,
          '2F' => :speaker_b,
          # Speaker level test mode
          '80' => :test,
          '8C' => :pure_direct,
        }.freeze
      end
    end
  end
end
