module Seriamp
  class Error < StandardError; end
  class NoDevice < Error; end
  class BadDevice < Error; end
  class InvalidCommand < Error; end
  class NotApplicable < Error; end
  class UnexpectedResponse < Error; end
  class HandshakeFailure < UnexpectedResponse; end
  class CommunicationTimeout < Error; end
end
