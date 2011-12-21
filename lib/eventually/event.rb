require 'eventually'
require 'eventually/callable'

module Eventually
  class Event
    attr_reader :name, :callables
    
    def initialize(name, emittable=true)
      @name = name.to_sym
      @emittable = !!emittable
      @callables = []
    end
    
    def add_callable(callable)
      raise "Event type :#{name} will not be emitted." unless emittable?
      @callables << callable if callable_valid?(callable)
    end
    
    def remove_callable(callable_to_remove)
      if callable_valid?(callable_to_remove)
        delete_handler = proc{|callable| callable == callable_to_remove }
      else
        delete_handler = proc{|callable| callable.callable == callable_to_remove }
      end
      @callables.delete_if(&delete_handler)
    end
    
    def remove_all_callables
      @callables = []
    end
    
    def emit(*payload)
      raise "Event type :#{name} cannot be emitted." unless emittable?
      @callables.each {|callable| callable.call(*payload) }
      @callables.delete_if {|callable| !callable.continuous? }
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