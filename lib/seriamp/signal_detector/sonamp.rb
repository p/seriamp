# frozen_string_literal: true

module Seriamp
  module SignalDetector

    # Determines receiver power status by inspecting signal sensing
    # state of the amplifier. Essentially this mirrors how the amplifier
    # itself handles the automatic power management.
    #
    # This may not work when amplifier is set to high gain and input
    # signal level is low - the amplifier may not consider the input
    # signal to be above threshold. You can use the receiver detector
    # in this case.
    class Sonamp
      def initialize(**opts)
        @options = opts.dup.freeze

        # The daemon needs the sonamp client anyway to turn the power
        # on and off, thus require the client to be passed to this
        # detector.
        @sonamp_client = opts.fetch(:sonamp_client)
      end

      def on?
        # There isn't an "all" auto trigger input return - sonamp
        # only returns per-zone auto triggers.
        # If any of the zones have audio signal, consider the amplifier
        # to be receiving audio from the receiver.
        # This seems like reasonable behavior when the amplifier is
        # connected to a single receiver outputting one zone of audio,
        # but perhaps wouldn't work well in a multi-zone installation.
        # A multi-zone installation however would likely need different
        # rules for how to turn the amplifier on (perhaps, for example,
        # based on simply auto trigger input for each zone).
        sonamp_client.get_json('auto_trigger_input').values.any? { |v| v == true }
      end

      private

      attr_reader :sonamp_client
    end
  end
end
