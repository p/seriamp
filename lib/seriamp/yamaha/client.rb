# frozen_string_literal: true

require 'timeout'
require 'seriamp/utils'
require 'seriamp/backend'
require 'seriamp/yamaha/protocol/methods'
require 'seriamp/yamaha/protocol/get_constants'
require 'seriamp/yamaha/protocol/status'
require 'seriamp/yamaha/constants'
require 'seriamp/yamaha/parser'
require 'seriamp/yamaha/response'
require 'seriamp/client'

module Seriamp
  module Yamaha

    class Client < Seriamp::Client
      include Parser
      include Constants

      # Yamahas do not care what flow control is set to.
      MODEM_PARAMS = {
        baud: 9600,
        data_bits: 8,
        stop_bits: 1,
        parity: 0, # SerialPort::NONE
      }.freeze

      # The manual says response should be received in 500 ms.
      # However, the status response takes 850 ms to be received in my
      # environment (RX-V1500/1800/2500).
      # 1 second is insufficient here to turn the receiver on after it has
      # just been powered off.
      # For RX-V2700, this timeout is insufficient when powering up
      # the receiver from standby.
      DEFAULT_RS232_TIMEOUT = 2

      include Protocol::Methods

      def present?
        # TODO find a faster command to issue
        status
        true
      end

      def status_string
        with_lock do
          with_retry do
            with_device do
              dispatch(STATUS_REQ)
              # There could potentialy be multiple responses here if
              # receiver is sending status updates to host?
              extract_one_response!
            end
          end
        end
      end

      def status
        with_lock do
          with_retry do
            with_device do
              resp = nil
              dispatch(STATUS_REQ, read_response: false)
              status = get_specific_response(cls: Response::StatusResponse).state
              # Device could have been closed by now.
              # TODO keep the device open the entire time if thread safety
              # (locking) is enabled.
              if @io
                buf = Utils.consume_data(@io, logger,
                  "Serial device readable after completely reading status response - concurrent access?")
                report_unread_response(buf)
              end

              @model_code, @version, @status_string =
                status.fetch(:model_code), status.fetch(:firmware_version),
                status.fetch(:raw_string)
              @status = status
            end
          end
        end
      end

      def all_status
        status.merge(
          all_io_assignments,
          tone,
          all_volume_trims,
        ).tap do |status|
          if parametric_eq?
            parametric_eq
          else
            graphic_eq
          end
          status.update(current_status)
        end
      end

      def current_status
        unless @current_status
          status
        end
        @current_status.dup
      end

      def clear_cache
        @status = nil
      end

      %i(
        model_code firmware_version system_status power main_power zone2_power
        zone3_power input input_name audio_source program_select
        main_volume zone2_volume zone3_volume
        program program_name sleep night night_name
        audio_format sample_rate
      ).each do |meth|
        define_method(meth) do
          status.fetch(meth)
        end
      end

      alias main_input_name input_name

      %i(
        multi_ch_input effect pure_direct speaker_a speaker_b
      ).each do |meth|
        define_method("#{meth}?") do
          status.fetch(meth)
        end
      end

      # Shows a message via the on-screen display. The message must be 16
      # characters or fewer. The message is NOT displayed on the front panel,
      # it is shown only on the connected TV's OSD.
      def osd_message(msg)
        if msg.length < 16
          msg = msg.dup
          while msg.length < 16
            msg += ' '
          end
        elsif msg.length > 16
          raise ArgumentError, "Message must be no more than 16 characters, #{msg.length} given"
        end

        with_lock do
          with_retry do
            with_device do
              @io.syswrite("#{STX}21000#{ETX}".encode('ascii'))
              @io.syswrite("#{STX}3#{msg[0..3]}#{ETX}".encode('ascii'))
              @io.syswrite("#{STX}3#{msg[4..7]}#{ETX}".encode('ascii'))
              @io.syswrite("#{STX}3#{msg[8..11]}#{ETX}".encode('ascii'))
              @io.syswrite("#{STX}3#{msg[12..15]}#{ETX}".encode('ascii'))
              @io.clear_rts
            end
          end
        end

        nil
      end

      def remote_command(cmd, read_response: true, expect_response_state: nil, include_response_state: nil)
        if expect_response_state || include_response_state and !read_response
          raise ArgumentError, "Cannot accept response requirements when asked not to read the response"
        end
        cmd = "#{STX}0#{cmd}#{ETX}"
        with_lock do
          with_retry do
            dispatch(cmd, read_response: false)
            if read_response
              resp = nil
              # Response should have been to our RS-232 command, verify.
              loop do
                with_device do
                  self.read_response
                end
                resp = get_specific_response(cls: Response::CommandResponse)
                if resp.control_type != :rs232
                  # Receiver can be sending system responses, ignore them.
                  #raise UnhandledResponse, "Response was not to our command: #{resp}"
                  update_current_status(resp)
                  next
                end
                if expect_response_state && !resp.state.keys.include?(expect_response_state)
                  logger&.debug("Wanted state: #{expect_response_state}; continuing to read")
                  next
                end
                break
              end
              resp.state
            end
          end
        end
      end

      def system_command(cmd)
        with_lock do
          with_retry do
            resp = dispatch_and_parse("#{STX}2#{cmd}#{ETX}")
            if resp.control_type != :rs232
              raise "Wrong control type: #{resp[:control_type]}"
            end
            if guard = resp.guard
              raise NotApplicable, "Command guarded by '#{guard}'"
            end
            resp.state
          end
        end
      end

      def extended_command(cmd)
        payload = frame_extended_request(cmd)
        with_lock do
          with_retry do
            dispatch_and_parse(payload)
          end
        end
      end

      private

      include Protocol::GetConstants

      STATUS_REQ = "#{DC1}001#{ETX}"

      ZERO_ORD = '0'.ord

      def response_complete?
        read_buf.end_with?(self.class.const_get(:ETX))
      end

      def extract_one_response
        # ETX and \0 are used differently - while ETX indicates the end
        # of a response, and the previous bytes go with the response,
        # \0 is the complete response and previous bytes should go with
        # the previous response (hopefully there is one...).
        extract_delimited_response(self.class.const_get(:ETX), "\0")
      end

      def parse_response(resp_str)
        Yamaha::Parser.parse(resp_str, logger: logger).tap do |resp|
          case resp
          when Yamaha::Response::NullResponse
            # This could be because the receiver is off (in standby)
            # or it's waking up, and we have no way to determine which it is.
            current_status = {}
          else
            # Sometimes the response isn't parsed (yet) by seriamp,
            # which causes state to be missing here...
            if resp.respond_to?(:state) && resp.state.nil?
              raise NotImplementedError, "Response was missing state: #{resp}"
            end

            # Extended commands that alter state (i.e. the "set X" commands)
            # have empty responses, i.e. the receiver does not report
            # the state back.
            # We need to store the state ourselves then based on the
            # issued command or perform a query.
            # (Extended commands with no state return an empty hash from
            # +to_state+).
            #binding.b unless resp

            update_current_status(resp.to_state)
          end
        end
      end

      def update_current_status(resp)
        logger&.debug("Updating current status: #{resp}")
        new_status = case resp
        when Hash
          resp
        else
          resp.state
        end
        if @current_status &&
          @current_status[:model_code] && new_status[:model_code] &&
          @current_status[:model_code] != new_status[:model_code]
        then
          @current_status = nil
        end
        if @current_status
          @current_status.update(new_status)
        else
          @current_status = new_status.dup
        end
      end

      # TODO what happens to surround back channels when there's only one?
      CHANNEL_KEYS = %i(
        front_left
        front_right
        center
        surround_left
        surround_right
        surround_back_left
        surround_back_right
        subwoofer
        presence_left
        presence_right
      ).freeze

      def extract_text(resp)
        # TODO: assert resp[0] == DC1, resp[-1] == ETX
        resp[0...-1]
      end

      def report_unread_response(buf)
        if buf.nil?
          raise ArgumentError, 'buffer should not be nil here'
        end

        return if buf.empty?

        if buf.count(ETX) > 1
          logger&.warn("Multiple unread responses: #{buf}")

          buf.split(ETX).each do |resp|
            report_unread_response(resp + ETX)
          end
          return
        end

        case buf[0]
        when DC2
          logger&.warn("Status response, #{buf.length} bytes")
        when STX
          logger&.warn("Command response: #{buf} #{Yamaha::Parser::CommandResponseParser.parse(buf[1...-1])}")
        else
          logger&.warn("Unknown unread response: #{buf}")
        end
      end

      def extend_next_deadline
        # 2 seconds here is definitely insufficient for RX-V1500 powering on
        @next_earliest_deadline = Utils.monotime + 3
      end
    end
  end
end
