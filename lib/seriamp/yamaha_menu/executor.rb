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

      LEFT = "\e[D"
      RIGHT = "\e[C"
      UP = "\e[A"
      DOWN = "\e[B"
      MENU = 'm'
      ENTER = 'e'
      RETURN = 'r'
      QUIT = 'q'

      ARROWS = {
        left: '7A9F',
        right: '7A9E',
        up: '7A9D',
        down: '7A9C',
      }.freeze

      COMMANDS = ARROWS.merge(
        menu: '7AA0',
        enter: '7ADE',
        return: '7AA1',
      )

      def run_command(cmd, *args)
        puts "Keys: Left/Right/Up/Down arrows"
        puts "      (m)enu (e)nter (r)eturn (q)uit"
        commands = COMMANDS
        case cmd
        when 'menu'
          loop do
            case key = input_reader.get_key
            when LEFT
              client.remote_command(commands.fetch(:left), read_response: false)
            when RIGHT
              client.remote_command(commands.fetch(:right), read_response: false)
            when UP
              client.remote_command(commands.fetch(:up), read_response: false)
            when DOWN
              client.remote_command(commands.fetch(:down), read_response: false)
            when MENU, MENU.upcase
              client.remote_command(commands.fetch(:menu), read_response: false)
            when ENTER, ENTER.upcase
              client.remote_command(commands.fetch(:enter), read_response: false)
            when RETURN, RETURN.upcase
              client.remote_command(commands.fetch(:return), read_response: false)
            when QUIT, QUIT.upcase
              break
            end
          end
        end
      end
    end
  end
end
