module Seriamp
  module Yamaha
    module Protocol
      module Extended
        class GenericResponse
          def initialize(cmd, value)
            @cmd = cmd
            @value = value
          end

          attr_reader :cmd
          attr_reader :value

          def to_s
            "#<#{self.class.name}: #{cmd} #{value}"
          end
        end
      end
    end
  end
end
