# frozen_string_literal: true

require 'seriamp/yamaha/executor'

module Seriamp
  module Ynca
    class Executor < Yamaha::Executor
      def run_command(cmd, *args)
        cmd = cmd.gsub('_', '-')
        case cmd
        when 'raw'
          p client.dispatch(*args)
        when 'model-name'
          p client.model_name
        else
          super
        end
      end
    end
  end
end
