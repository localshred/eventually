module Eventually
  module Validation
    class MaxListeners
      def initialize(emitter)
        @emitter = emitter
      end
      
      def valid?
        @emitter.class.max_listeners == 0 || @emitter.num_listeners <= @emitter.class.max_listeners
      end
      
      def warn_unless_valid!
        puts "Warning: #{@emitter.class.name} has more than #{@emitter.class.max_listeners} registered listeners." unless valid?
      end
    end
  end
end