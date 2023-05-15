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
        enter: ['e', ?\x0D],
        return: 'r',
        quit: 'q',
      }.freeze

      ARROWS = {
        left: '7A9F',
        right: '7A9E',
        up: '7A9D',
        down: '7A9C',
      }.freeze

      COMMANDS = ARROWS.merge(
        # Verified on: RX-V2700 (return exits menu completely)
        menu: '7AA0',
        enter: '7ADE',
        return: '7AA1',
      )

      KEYS_INVERTED = Hash[KEYS.invert.map do |k, v|
        Array(k).map do |each_k|
          [each_k, v]
        end
      end.flatten(1)].freeze

      def run_command(cmd, *args)
        case cmd
        when 'menu'
          puts
          puts "Keys: Left/Right/Up/Down arrows"
          puts "      Enter or (e) to enter submenu, on some receivers use Right arrow instead"
          puts "      (r) to return to parent menu, on some receivers this exits setup completely"
          puts "      (m) to re-enter the setup menu"
          puts "      (q) to exit this program"
          puts
          puts "Some receivers have separate parameter menus in addition to the main setup menu,"
          puts "this program does not handle the additional menus at this time."
          puts
          commands = COMMANDS
          client.remote_command(commands.fetch(:menu), read_response: false)

          loop do
            key = input_reader.get_key
            if key.include?(?\e)
              cmd = KEYS_INVERTED[key]
            else
              cmd = KEYS_INVERTED[key.downcase]
            end

            next unless cmd

            if cmd == :quit
              break
            end
            remote_command = commands.fetch(cmd)
            client.remote_command(remote_command, read_response: false)
          end
        end
      end
    end
  end
end
