require 'eventually'
require 'eventually/callable'

module Eventually
  class Event
    attr_reader :name, :listeners
    
    def initialize(name, emittable=true)
      @name = name.to_sym
      @emittable = !!emittable
      @listeners = []
    end
    
    def add_callable(callable)
      raise "Event type :#{name} will not be emitted." unless emittable?
      @listeners << callable if callable_valid?(callable)
    end
    
    def emit(*payload)
      raise "Event type :#{name} cannot be emitted." unless emittable?
      @listeners.each {|callable| callable.call(*payload) }
      @listeners.delete_if {|callable| !callable.continuous? }
    end
    
    def callable_valid?(callable)
      callable.is_a?(Eventually::Callable)
    end
    
    def emittable?
      @emittable
    end
    alias :registerable? :emittable?
  end
end