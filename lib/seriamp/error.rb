module Seriamp
  class Error < StandardError; end
  class InvalidCommand < Error; end
  class NotApplicable < Error; end
  class UnexpectedResponse < Error; end
  class CommunicationTimeout < Error; end
end
