# frozen_string_literal: true

module Seriamp
  class RecursiveMutex < Mutex
    def synchronize(&block)
      if owned?
        yield
      else
        super
      end
    end
  end
end
