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
                main_volume: main_volume,
              }
            end
          end
        end
      end

      [
        [:model_name, 'SYS', 'MODELNAME', :string],
        [:main_power, 'MAIN', 'PWR', :boolean],
        [:main_volume, 'MAIN', 'VOL', :volume],
      ].each do |meth, _subunit, _function, _serializer|
        subunit, function, serializer = _subunit, _function, _serializer

        define_method(meth) do
          send("deserialize_#{serializer}", query(subunit, function))
        end

        define_method("set_#{meth}") do |value|
          send("deserialize_#{serializer}",
            set(subunit, function, send("serialize_#{serializer}", value)))
        end
      end

      [
        [:main_volume_up, 'MAIN', 'VOL', 'Up', :volume],
        [:main_volume_down, 'MAIN', 'VOL', 'Down', :volume],
      ].each do |meth, _subunit, _function, _value, _serializer|
        subunit, function, value, serializer = _subunit, _function, _value, _serializer

        define_method(meth) do
          send("deserialize_#{serializer}", set(subunit, function, value))
        end
      end

      def remote_command(cmd)
        with_lock do
          with_retry do
            dispatch("@SYS:REMOTECODE=#{cmd}#{ETX}")
          end
        end
      end

      def query(subunit, function)
        set(subunit, function, '?')
      end

      def set(subunit, function, value)
        dispatch_and_parse("@#{subunit}:#{function}=#{value}#{ETX}").fetch(:value)
      end

      public :dispatch

      private

      def write_command(cmd)
        @io.syswrite(cmd.encode('ascii') + ETX)
      end

      def parse_response(resp)
        if resp =~ /\A@(\w+):(\w+)=(.+)\r\n\z/
          {subunit: $1, function: $2, value: $3}
        else
          raise NotImplementedError, "Response format unknown: #{resp}"
        end
      end

      def deserialize_string(value)
        value
      end

      def serialize_string(value)
        value
      end

      def serialize_boolean(value)
        value ? 'On' : 'Off'
      end

      def deserialize_boolean(value)
        case value
        when 'On'
          true
        when 'Off'
          false
        else
          raise NotImplementedError, "Unknown boolean value: #{value}"
        end
      end

      def serialize_volume(value)
        '%.1f' % Float(value)
      end

      def deserialize_volume(value)
        Float(value)
      end
    end
  end
end
