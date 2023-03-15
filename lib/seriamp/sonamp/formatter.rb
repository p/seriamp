# frozen_string_literal: true

require 'seriamp/formatter'

module Seriamp
  module Sonamp
    class Formatter < Seriamp::Formatter
      def format_status(result)
        out = +''
        result.each do |k, value|
          formatted_value = case value
          when Hash
            if value.values.all? { |v| v == true || v == false }
              i = 0
              '[ ' + value.values.map do |v|
                i += 1
                if v
                  i.to_s
                else
                  ' '
                end
              end.join(' ') + ' ]'
            else
              '[ ' + value.map do |k, v|
                "#{k}:#{v}"
              end.join(' ') + ' ]'
            end
          else
            value.to_s
          end
          out << "#{k}: #{formatted_value}\n"
        end
        out
      end
    end
  end
end
