require 'eventually/callable'
module Eventually
  module Validation
    class Arity
      attr_reader :expected, :received
      def initialize(event, emitter, arity)
        @event = event
        @emitter = emitter
        @arity = @received = arity
        @expected = @emitter.class.arity_for_event(@event)
      end
      
      def valid?
        !@emitter.class.validates_arity?(@event) || @received == @expected
      end
      
      def raise_unless_valid!
        raise "Arity validation failed for event :#{@event} (expected #{@expected}, received #{@received})" unless valid?
      end
    end
  end
end
