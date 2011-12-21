require 'spec_helper'

class Emitter
  include Eventually
end

describe Eventually do
  before(:each) do
    Emitter.disable_strict!
    Emitter.emits_none
    Emitter.emits(:listener_added, :arity => 1)
    Emitter.max_listeners = 10
  end
  
  let(:emitter) { Emitter.new }
  let(:defined_events) { [:one, :two, :three] }
  
  context 'external api' do
    describe '.max_listeners' do
      it 'returns the number of listeners allowed before memory warnings are printed' do
        Emitter.max_listeners.should eq 10
      end
    end
    
    describe '.max_listeners=' do
      it 'sets the max number of listeners to allow before printing memory warnings' do
        Emitter.max_listeners = 20
        Emitter.max_listeners.should eq 20
      end
    end
    
    describe '.emits_none' do
      it 'clears out emitter definitions' do
        Emitter.emits(:jigger)
        Emitter.emits?(:jigger).should be_true
        Emitter.emits_none
        Emitter.emits?(:jigger).should be_false
      end
    end
    
    describe '.emits' do
      it 'allows event definition at class level' do
        Emitter.emits(:jigger)
        Emitter.emits?(:jigger).should be_true
      end
      
      it 'can register multiple event symbols at once' do
        Emitter.emits(*defined_events)
        defined_events.each {|e| Emitter.emits?(e).should be_true }
      end
      
      it 'provides a list of pre-defined emittable events' do
        Emitter.emits(*defined_events)
        Emitter.emits.should eq [:listener_added, defined_events].flatten
      end
      
      describe '.enable_strict!' do
        it 'requires the event to have been pre-defined for watchers to register callbacks to it' do
          Emitter.enable_strict!
          Emitter.emits(:start)
          Emitter.emits?(:start).should be_true
          expect {
            emitter.on(:start, lambda{ puts 'hi' })
          }.should_not raise_error
          expect {
            emitter.on(:stop, lambda{ puts 'hi' })
          }.should raise_error(/Event type :stop will not be emitted/)
        end  
      end
      
      describe '.disable_strict!' do
        it 'disables strict mode' do
          Emitter.disable_strict!
          Emitter.emits?(:start).should be_false
          expect {
            emitter.on(:start, lambda{ puts 'hi' })
          }.should_not raise_error
        end
      end
      
      describe '.strict?' do
        context 'when strict mode is enabled' do
          it 'returns true' do
            Emitter.enable_strict!
            Emitter.strict?.should be_true
          end
        end
        
        context 'when strict mode is disabled' do
          it 'returns false' do
            Emitter.disable_strict!
            Emitter.strict?.should be_false
          end
        end
      end
      
      context 'when providing an arity validation' do
        it 'sets an arity expectation for future event callbacks' do
          Emitter.emits(:jigger, arity: 5)
          Emitter.emits?(:jigger)
          Emitter.validates_arity?(:jigger).should be_true
        end
        
        it 'allows 0 as a specified arity' do
          Emitter.emits(:jigger, arity: 0)
          Emitter.emits?(:jigger)
          Emitter.validates_arity?(:jigger).should be_true
        end
        
        describe '.arity_for_event' do
          it 'reports the arity requirement for the event, if any' do
            Emitter.emits(:jigger, arity: 5)
            Emitter.arity_for_event(:jigger).should eq 5
            Emitter.emits(:pingpong)
            Emitter.arity_for_event(:pingpong).should eq -2        
            Emitter.arity_for_event(:nonevent).should eq nil
          end
        end
      end
    end
    
    it 'allows multiple registrations for a given event' do
      emitter.on(:start) { puts 'hello' }
      emitter.on(:start) { puts 'world' }
    end
    
    describe '.emittable?' do
      context 'when strict mode enabled' do
        before { Emitter.enable_strict! }
        context 'when given event is registered' do
          it 'returns true' do
            Emitter.emits(:known)
            Emitter.emits?(:known).should be_true
            Emitter.emittable?(:known).should be_true
          end
        end
        context 'when given event is not registered' do
          it 'returns false' do
            Emitter.emits?(:unknown).should be_false
            Emitter.emittable?(:unknown).should be_false
          end
        end
      end
      
      context 'when strict mode disabled' do
        before { Emitter.disable_strict! }
        context 'when given event is registered' do
          it 'returns true' do
            Emitter.emits(:known)
            Emitter.emits?(:known).should be_true
            Emitter.emittable?(:known).should be_true
          end
        end
        context 'when given event is not registered' do
          it 'returns true' do
            Emitter.emits?(:unknown).should be_false
            Emitter.emittable?(:unknown).should be_true
          end
        end
      end
    end
  end
  
  describe '#on' do
    it 'raises an error when a given callback is invalid' do
      expect { emitter.on(:start, nil, &nil)  }.should raise_error(/Cannot register callable/)
      expect { emitter.on(:start, 10_000)     }.should raise_error(/Cannot register callable/)
      expect { emitter.on(:start, "callback") }.should raise_error(/Cannot register callable/)
    end
    
    context 'when arity validation is enabled' do
      before { Emitter.emits(:hello_world, arity: 2) }
      it 'accepts a callback with matching arity' do
        expect {
          emitter.on(:hello_world) do |param1, param2|
            # callback will not be invoked
          end
        }.should_not raise_error
      end
      
      it 'rejects a callback if the given arity is not exact' do
        expect {
          emitter.on(:hello_world) do |param1, param2, param3|
            # callback will not be invoked
          end
        }.should raise_error(/Arity validation failed for event :hello_world \(expected 2, received 3\)/)
      end
    end
    
    context 'when detecting potential memory leaks' do
      it 'writes a warning to stdout when > 10 listeners are added' do
        $stdout.should_receive(:puts).once.with('Warning: Emitter has more than 10 registered listeners.')
        (emitter.class.max_listeners+1).times do
          emitter.on(:some_event, lambda{})
        end
      end

      it 'will not print a warning if max_listeners is set to 0' do
        emitter.class.max_listeners = 0
        $stdout.should_not_receive(:puts).with('Warning: Emitter has more than 10 registered listeners.')
        1000.times do
          emitter.on(:some_event, lambda{})
        end
      end
    end
  end
  
  describe '#emit' do    
    let(:emitter) { Emitter.new }
    let(:watcher) { Watcher.new }
    
    class Watcher
      attr_accessor :value
      def initialize
        @value = 1
      end
      def block_callback
        Proc.new{|payload| @value += payload }
      end
      def lambda_callback
        lambda{|payload| @value += payload }
      end
      def method_callback
        method(:update_method)
      end
      def proc_callback
        proc{|payload| @value += payload }
      end
      def update_method(payload)
        @value += payload
      end
    end
    
    shared_examples_for 'emitting an event' do |cbk_type|
      it "by invoking a #{cbk_type} callback" do
        expect {          
          case cbk_type
          when :block then
            emitter.on(:start, &watcher.block_callback)
          when :lambda then
            emitter.on(:start, watcher.lambda_callback)
          when :method then
            emitter.on(:start, watcher.method_callback)
          when :proc then
            emitter.on(:start, watcher.proc_callback)
          end
        }.should_not raise_error(/Cannot register callback/)
        emitter.__send__(:emit, :start, 1)
        watcher.value.should eq 2
      end
    end
    
    it_behaves_like 'emitting an event', :block
    it_behaves_like 'emitting an event', :lambda
    it_behaves_like 'emitting an event', :method
    it_behaves_like 'emitting an event', :proc
    
    it 'emits an event on the emitter when a new listener is added' do
      callback_to_add = lambda{ puts 'hi' }
      listener_id = nil
      emitter.on(:listener_added) do |listener|
        listener_id = listener.callable.object_id
      end
      emitter.on(:some_event, callback_to_add)
      listener_id.should eq callback_to_add.object_id
    end
    
    it 'emits nothing when no event callbacks are given' do
      expect { emitter.__send__(:emit, :hullabaloo) }.should_not raise_error
    end
    
    it 'invokes registered callbacks in a FIFO manner' do
      watcher1 = Watcher.new
      watcher1.value = []
      
      watcher2 = Watcher.new
      watcher2.value = []
      
      emitter.on(:push) {|v| watcher1.value << "A"+v }
      emitter.on(:push) {|v| watcher2.value << "B"+v }
      emitter.on(:push) {|v| watcher2.value << "C"+v }
      emitter.on(:push) {|v| watcher1.value << "D"+v }
      emitter.__send__(:emit, :push, "-VALUE")
      
      watcher1.value.should eq ["A-VALUE", "D-VALUE"]
      watcher2.value.should eq ["B-VALUE", "C-VALUE"]
    end
    
    context 'when arity validation is enabled' do
      it 'emits the event when arity is valid' do
        emitter.class.emits(:hello_world, arity: 2)
        expect {
          emitter.__send__(:emit, :hello_world, "hello", "world")
        }.should_not raise_error
      end
      
      it 'rejects emitting an event when the arity is not exact' do
        emitter.class.emits(:hello_world, arity: 2)
        expect {
          emitter.__send__(:emit, :hello_world, "hello")
        }.should raise_error(/Arity validation failed for event :hello_world \(expected 2, received 1\)/)
      end
    end
    
    context 'when strict mode is enabled' do
      context 'when emitting an event not previously defined' do
        it 'raises an error concerning the unknown event type' do
          emitter.class.enable_strict!
          emitter.class.strict?.should be_true
          emitter.class.emits?(:stop).should be_false
          expect {
            emitter.__send__(:emit, :stop)
          }.should raise_error(/Event type :stop cannot be emitted/)
        end
      end
    end
  end
  
  describe '#once' do
    it 'registers to an event for one time only, then releases the registration' do
      value = 1
      emitter.once(:start) do
        value += 1
      end
      listener_count = emitter.num_listeners
      
      emitter.__send__(:emit, :start)
      emitter.__send__(:emit, :start)
      value.should eq 2
      emitter.num_listeners.should eq(listener_count - 1)
    end
  end
  
  describe '#remove_listener' do
    it 'removes a given event callback' do
      value = 1
      cbk = lambda{ value += 1 }
      emitter.on(:some_event, cbk)
      emitter.__send__(:emit, :some_event)
      value.should eq 2
      emitter.remove_listener(:some_event, cbk)
      emitter.__send__(:emit, :some_event)
      value.should eq 2
    end
  end
  
  describe '#remove_all_listeners' do
    it 'removes all listeners for the given event' do
      value = 1
      emitter.on(:some_event) do
        value += 1
      end
      emitter.on(:some_event) do
        value += 5
      end
      emitter.on(:some_event) do
        value += 10
      end
      emitter.__send__(:emit, :some_event)
      value.should eq 17
      
      emitter.remove_all_listeners(:some_event)
      emitter.__send__(:emit, :some_event)
      value.should eq 17
    end
  end
  
  describe '#listeners' do
    it 'returns a list of listener callbacks for the given event' do
      cb1 = lambda{}
      cb2 = lambda{}
      cb3 = lambda{}
      emitter.on(:some_event, cb1)
      emitter.on(:some_event, cb2)
      emitter.on(:some_event, cb3)
      emitter.listeners(:some_event).should eq [cb1, cb2, cb3]
    end
  end
  
  describe '#num_listeners' do
    it 'counts all listeners across all events' do
      emitter.on(:event1, lambda{})
      emitter.on(:event2, lambda{})
      emitter.on(:event3, lambda{})
      emitter.num_listeners.should eq 3
    end
  end
  
end