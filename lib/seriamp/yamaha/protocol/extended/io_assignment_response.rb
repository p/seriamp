# frozen_string_literal: true

module Seriamp
  module Yamaha
    module Protocol
      module Extended
        class IoAssignmentResponse < ResponseBase
          include Yamaha::Helpers

          register '010'

          def initialize(cmd, value)
            super

            if value.length != 4
              raise ArgumentError, "Invalid value length: expected 4: #{value}"
            end

            @jack_type = GetConstants::IO_ASSIGNMENT_JACK_TYPE_GET.fetch(value[0])
            @jack_number = Integer(value[1]) + 1
            # Could also use INPUT_NAME_2_GET here, but the names in
            # INPUT_NAME_2_GET are not for receivers that permit I/O assignment
            # setting/retrieval via this function.
            # Note that not all inputs mentioned in the input trim input list
            # can be assigned.
            @input_name = GetConstants::VOLUME_TRIM_INPUT_NAME_2_GET.fetch(value[2..3])
          end

          attr_reader :jack_type
          attr_reader :jack_number
          attr_reader :input_name

          def to_s
            "#<#{self.class.name}: #{jack_type.to_s.sub('_', ' ')} #{jack_number} -> #{input_name}>"
          end

          def to_state
            {"#{jack_type}_#{jack_number}_io_assignment": input_name}
          end
        end
      end
    end
  end
end
