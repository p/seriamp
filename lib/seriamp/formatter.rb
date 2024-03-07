# frozen_string_literal: true

autoload :PP, 'pp'
autoload :StringIO, 'stringio'

module Seriamp
  class Formatter
    def format(value)
      if Hash === value
        io = StringIO.new
        PP.pp(value, io).string
      else
        value.to_s
      end
    end
  end
end
