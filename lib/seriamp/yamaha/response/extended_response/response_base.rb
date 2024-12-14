# frozen_string_literal: true

module Seriamp
  module Yamaha
    module Response
      module ExtendedResponse
        class ResponseBase
          def initialize(cmd, value)
            @cmd = cmd
            @value = value
          end

          attr_reader :cmd
          attr_reader :value

          def to_s
            "#<#{self.class.name}: #{cmd} #{value}>"
          end

          class << self
            def registered_responses
              @registered_responses ||= {}
            end

            def register(code)
              ResponseBase.registered_responses[code] = self
            end
          end
        end
      end
    end
  end
end
