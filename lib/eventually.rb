require "eventually/version"

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
    NO_CHECK_ARITY = -1
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
    
    def max_listeners
      @max_listeners ||= DEFAULT_MAX_LISTENERS
    end
    
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
    
    # Are we strict or not
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
    def can_emit_or_register?(event)
      !strict? || emits?(event)
    end
    
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
  def on(event, callable=nil, &blk)
    raise "Event type :#{event} will not be emitted. Use #{self.class.name}.emits(:#{event})" unless self.class.can_emit_or_register?(event)
    
    cbk = pick_callback(callable, blk)
    
    unless valid_event_arity?(event, cbk.arity)
      raise "Invalid callback arity for event :#{event} (expected #{self.class.arity_for_event(event)}, received #{cbk.arity})"
    end
    
    (__registered__[event.to_sym] ||= []) << cbk
    emit(:listener_added, cbk)
    
    if self.class.max_listeners > 0 && __registered__[event.to_sym].count > self.class.max_listeners
      puts 'Event emitter has registered more than 10 listeners. This may be a memory leak situation.'
    end
    
    cbk
  end
  
  def once(event, callable=nil, &blk)
    cbk = on(event, callable, &blk)
    (__onceable__[event.to_sym] ||= {})[cbk.object_id] = true
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
  def emit(event, *payload)
    raise "Event type :#{event} cannot be emitted. Use #{self.class.name}.emits(:#{event})" unless self.class.can_emit_or_register?(event)
    
    unless valid_event_arity?(event, payload.length)
      raise "Invalid emit arity for event :#{event} (expected #{self.class.arity_for_event(event)}, received #{payload.length})"
    end
    
    (listeners(event) || []).each do |cbk|
      cbk.call(*payload)
      listeners(event).delete_if{|cbk| __onceable__.fetch(event.to_sym){Hash.new}.key?(cbk.object_id) }
    end
    __onceable__[event.to_sym] = Hash.new
  end
  
  def listeners(event)
    __registered__[event.to_sym]
  end
  
  def remove_listener(event, cbk)
    listeners(event).delete_if{|reg_cbk| reg_cbk == cbk }
  end
  
  def remove_all_listeners(event)
    __registered__[event.to_sym] = []
  end
  
  def pick_callback(callable, blk)
    cbk = nil
    if callable.respond_to?(:call)
      cbk = callable
    elsif blk && !blk.nil?
      cbk = blk
    else
      raise 'Cannot register callback. Neither callable nor block was given'
    end
    cbk
  end
  
  # Shorthand predicate to determine if the given cbk for this event
  # has a valid arity amount
  def valid_event_arity?(event, arity_count)
    expected_arity = self.class.arity_for_event(event)
    !self.class.validates_arity?(event) || arity_count == expected_arity
  end
  
  private
  
  def __registered__
    @__registered__ ||= {}
  end
  
  def __onceable__
    @__onceable__ ||= {}
  end
  
end
