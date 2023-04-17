# frozen_string_literal: true

require 'seriamp/yamaha_menu/input_reader'

module Seriamp
  module YamahaMenu
    class Executor
      def initialize(client, **opts)
        @client = client
        @options = opts.dup.freeze
        @input_reader = InputReader.new
      end

      attr_reader :client
      attr_reader :options
      attr_reader :input_reader

      KEYS = {
        left: "\e[D",
        right: "\e[C",
        up: "\e[A",
        down: "\e[B",
        menu: 'm',
        enter: 'e',
        return: 'r',
        quit: 'q',
      }.freeze

      ARROWS = {
        left: '7A9F',
        right: '7A9E',
        up: '7A9D',
        down: '7A9C',
      }.freeze

      COMMANDS_RX_V1500 = ARROWS.merge(
        # These are not working
        menu: '7AA0',
        enter: '7ADE',
        return: '7AA1',
      )

      KEYS_INVERTED = KEYS.invert.freeze

      def run_command(cmd, *args)
        puts "Keys: Left/Right/Up/Down arrows"
        puts "      (m)enu (e)nter (r)eturn (q)uit"
        commands = COMMANDS_RX_V1500
        case cmd
        when 'menu'
          loop do
            key = input_reader.get_key
            if key.include?(?\e)
              cmd = KEYS_INVERTED[key]
            else
              cmd = KEYS_INVERTED[key.downcase]
            end

            next unless cmd

            cmd = commands.fetch(cmd)
            client.remote_command(cmd, read_response: false)
          end
        end
      end
    end
  end
end
