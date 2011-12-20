require "eventually/version"

module Eventually
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    NO_CHECK_ARITY = -1
    attr_accessor :emittable_events
    
    def enable_strict!
      @strict = true
    end
    
    def disable_strict!
      @strict = false
    end
    
    def strict?
      @strict || false
    end
    
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
    
    def emits?(evt)
      emittable.key?(evt.to_sym)
    end
    
    def validates_arity?(evt)
      emits?(evt) && emittable[evt.to_sym] > NO_CHECK_ARITY
    end
    
    def arity_for_event(evt)
      emits?(evt) ? emittable[evt.to_sym] : nil
    end
    
    def emits_none
      @emittable = {}
      nil
    end
    
    def can_emit_or_register?(event)
      !strict? || emits?(event)
    end
    
    private
    
    def emittable
      @emittable ||= {}
    end
  end
  
  def on(event, callable=nil, &blk)
    raise "Event type :#{event} will not be emitted. Use #{self.class.name}.emits(:#{event})" unless self.class.can_emit_or_register?(event)
    
    cbk = nil
    if callable.respond_to?(:call)
      cbk = callable
    elsif block_given? && !blk.nil?
      cbk = blk
    else
      raise 'Cannot register callback. Neither callable nor block was given'
    end
    
    if self.class.validates_arity?(event) && cbk.arity != (expected_arity = self.class.arity_for_event(event))
      raise "Invalid callback arity for event :#{event} (expected #{expected_arity}, received #{cbk.arity})"
    end
    
    (__registered__[event.to_sym] ||= []) << cbk
  end
  
  def emit(event, *payload)
    raise "Event type :#{event} cannot be emitted. Use #{self.class.name}.emits(:#{event})" unless self.class.can_emit_or_register?(event)
    
    __registered__[event.to_sym].each do |cbk|
      cbk.call(*payload)
    end
  end
  
  private
  
  def __registered__
    @__registered__ ||= {}
  end
  
end
