require 'forwardable'
require 'eventually/validation/arity'

module Eventually
  class Callable
    extend Forwardable
    attr_reader :callable
    attr_accessor :availability
    
    delegate [:arity, :call, :to_proc] => :@callable
    
    def initialize(callable, block, availability=:continuous)
      @callable = pick_callable(callable, block)
      @availability = availability
    end
    
    def pick_callable(c, b)
      cb = nil
      if c.respond_to?(:call)
        cb = c
      elsif !b.nil?
        cb = b
      else
        raise 'Cannot register callable. Neither callable nor block was given.'
      end
    end
    
    def validate_arity_or_raise(event, emitter)
      Eventually::Validation::Arity.new(event, emitter, arity).raise_unless_valid!
    end
    
    def continuous?
      @availability == :continuous
    end
    
  end
end
  