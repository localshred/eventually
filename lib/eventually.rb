require 'eventually/version'
require 'eventually/event'
require 'eventually/callable'
require 'eventually/validation/arity'
require 'eventually/validation/max_listeners'

# Eventually is a module that facilitates evented callback
# management similar to the EventEmitter API in NodeJS.
# Simply include in the class you will be emitting events
# from and fire away.
#
# Support exists for strict mode, pre-defining the events
# you plan on emitting, and arity validation on callbacks.
# See the docs below or the examples folder for further documentation.
module Eventually
  def self.included(base)
    base.extend(ClassMethods)
    base.emits(:listener_added, :arity => 1)
  end
  
  module ClassMethods
    NO_CHECK_ARITY = -2
    DEFAULT_MAX_LISTENERS = 10
    
    attr_accessor :emittable_events
    
    # Define an event or list of events
    # that instances of this class will potentially emit.
    #
    # Usage (list of events):
    #    emits :started, :stopped
    #
    # Usage (single event):
    #    emits :started
    #
    # Usage (single event with arity validation):
    #    emits :started, :arity => 2
    #
    def emits(*evts)
      if evts && !evts.empty?
        if evts.all?{|e| e.is_a?(Symbol) }
          evts.each{|e| emittable[e.to_sym] = NO_CHECK_ARITY }
        elsif evts.count == 2
          emittable[evts[0].to_sym] = (evts[1].fetch(:arity) { NO_CHECK_ARITY }).to_i
        end
      else
        emittable.keys
      end
    end
    
    # Check if instances of this class have pre-defined
    # the given event as potentially emittable
    def emits?(evt)
      emittable.key?(evt.to_sym)
    end
    
    # Return the maximum number of listeners before
    # we'll start printing memory warnings.
    # Default max is 10
    def max_listeners
      @max_listeners ||= DEFAULT_MAX_LISTENERS
    end
    
    # Set the maximum listener number. Setting this max
    # to 0 indicates unlimited listeners allowed.
    def max_listeners= max
      @max_listeners = max
    end
    
    # Puts instances into strict mode. This does two things:
    #   - Raise an error if registering a callback for an event
    #     that has not already been pre-defined (e.g. with #emits)
    #   - Raise an error if instance attempts to emit an event
    #     that has not already been pre-defined (e.g. with #emits)    
    def enable_strict!
      @strict = true
    end
    
    # The default state of an Eventually instance. Does not require
    # pre-definition of an event to register against it or emit it
    def disable_strict!
      @strict = false
    end
    
    # Report on strict mode
    def strict?
      @strict || false
    end
    
    # Determines if the given event has an arity validation assigned
    def validates_arity?(evt)
      emits?(evt) && emittable[evt.to_sym] > NO_CHECK_ARITY
    end
    
    # Returns the arity validation, nil if event isn't defined
    def arity_for_event(evt)
      emits?(evt) ? emittable[evt.to_sym] : nil
    end
    
    # Reset the known emittable events (events defined with #emits)
    # More useful for tests probably, but leaving it in API just 'cause
    def emits_none
      @emittable = {}
      nil
    end
    
    # Shorthand predicate to determine if a given event is 
    # "emittable" or "registerable"
    def emittable?(event)
      !strict? || emits?(event)
    end
    alias :registerable? :emittable?
    
    private
    
    def emittable
      @emittable ||= {}
    end
  end # ClassMethods
  
  # Event registration method. Takes an event to register against and either
  # a callable object (e.g. proc/lambda/detached method) or a block
  # 
  # Usage: see Eventually#emit or examples directory
  #
  def on(evt_name, callable=nil, &blk)
    evt_name = evt_name.to_sym unless evt_name.is_a?(Symbol)
    
    cb = Eventually::Callable.new(callable, blk)
    cb.validate_arity_or_raise(evt_name, self)
    
    event = get_event(evt_name)
    event.add_callable(cb)
    emit(:listener_added, cb)
    
    Eventually::Validation::MaxListeners.new(self).warn_unless_valid!
    [event, cb]
  end
  
  # Event registration method which will remove the given
  # callback after it is invoked. See Eventually#on for registration details.
  def once(event, callable=nil, &blk)
    event, cb = on(event, callable, &blk)
    cb.availability = :once
    [event, cb]
  end
  
  def get_event(event)
    evt = _events[event]
    unless evt
      evt = Eventually::Event.new(event, self.class.registerable?(event))
      _events[event] = evt
    end
    evt
  end
  
  def num_listeners
    _events.values.inject(0){|acc, evt| acc + evt.listeners.size}
  end
  
  # Emit the payload arguments back to the registered listeners
  # on the given event. FIFO calling, and we won't deal with 
  # concurrency, so it should be handled at the callback level.
  # 
  # Usage:
  #   class Car
  #     include Eventually
  #     def stop
  #       #...
  #       emit(:stopped, 0)
  #     end
  #   end
  #
  #   car = Car.new
  #   car.on(:stopped) do |mph|
  #     puts 'the car stopped, sitting at %d mph' % mph
  #   end
  #   car.stop # this will indirectly invoke the above callback
  #
  def emit(evt_name, *payload)
    evt_name = evt_name.to_sym unless evt_name.is_a?(Symbol)
    event = get_event(evt_name)
    Eventually::Validation::Arity.new(evt_name, self, payload.length).raise_unless_valid!
    event.emit(*payload)
  end
  
  # Report the number of registered listeners for the given event
  def listeners(event)
    _events[event.to_sym]
  end
  
  # Remove the given listener callback from the given event callback list
  def remove_listener(event, cbk)
    listeners(event).delete_if{|reg_cbk| reg_cbk == cbk }
  end
  
  # Remove all listener callbacks for the given event
  def remove_all_listeners(event)
    _events[event.to_sym] = []
  end
  
  private
  
  def _events
    @_events ||= {}
  end
  
end
