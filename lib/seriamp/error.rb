module Seriamp
  class Error < StandardError; end
  class IndeterminateDevice < Error; end
  class NoDevice < Error; end
  class BadDevice < Error; end
  class InvalidCommand < Error; end
  class NotApplicable < Error; end
  class NoResponse < Error; end
  class UnexpectedResponse < Error; end
  class UnhandledResponse < Error; end
  class HandshakeFailure < UnexpectedResponse; end
  class CommunicationTimeout < Error; end

  class InvalidOnOffValue < ArgumentError; end
  class InvalidBackend < ArgumentError; end

  class NoPowerStateAvailable < Error; end
end
