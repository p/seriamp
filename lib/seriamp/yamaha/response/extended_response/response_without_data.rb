# frozen_string_literal: true

module Seriamp
  module Yamaha
    module Response
      module ExtendedResponse
        class ResponseWithoutData
          # TODO take command name (human-readable) as a parameter?
          def initialize(cmd)
            @cmd = cmd
          end

          attr_reader :cmd

          def to_s
            "#<#{self.class.name}: #{cmd} without data>"
          end
          
          def to_state
            {}
          end
        end
      end
    end
  end
end
