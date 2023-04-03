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
        end
      end
    end
  end
end
