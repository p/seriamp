# frozen_string_literal: true

require 'seriamp/yamaha/client'

module Seriamp
  module Ynca
    class Client < Yamaha::Client
      ETX = "\r\n"

      def status
        with_lock do
          with_retry do
            with_device do
              {
                main_power: main_power,
              }
            end
          end
        end
      end

      [
        [:main_power, 'MAIN', 'PWR'],
        [:main_volume, 'MAIN', 'VOL'],
      ].each do |meth, _subunit, _function|
        subunit, function = _subunit, _function

        define_method(meth) do
          query(subunit, function)
        end

        define_method("set_#{meth}") do |value|
          set(subunit, function, value)
        end
      end

      [
        [:main_volume_up, 'MAIN', 'VOL', 'Up'],
        [:main_volume_down, 'MAIN', 'VOL', 'Down'],
      ].each do |meth, _subunit, _function, _value|
        subunit, function, value = _subunit, _function, _value

        define_method(meth) do
          set(subunit, function, value)
        end
      end

      def remote_command(cmd)
        with_lock do
          with_retry do
            dispatch("@SYS:REMOTECODE=#{cmd}")
          end
        end
      end

      def query(subunit, function)
        set(subunit, function, '?')
      end

      def set(subunit, function, value)
        dispatch("@#{subunit}:#{function}=#{value}").fetch(:value)
      end

      private

      def write_command(cmd)
        @io.syswrite(cmd.encode('ascii') + ETX)
      end

      def parse_response(resp)
        if resp =~ /\A@(\w+):(\w+)=(.+)\r\n\z/
          {subunit: $1, function: $2, value: parse_value($3)}
        else
          raise NotImplementedError, "Response format unknown: #{resp}"
        end
      end

      def parse_value(value)
        case value
        when 'On'
          true
        when 'Off'
          false
        else
          value
        end
      end
    end
  end
end
