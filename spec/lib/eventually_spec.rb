require 'spec_helper'

class Emitter
  include Eventually
end

describe Eventually do
  before(:each) do
    Emitter.disable_strict!
    Emitter.emits_none
  end
  
  let(:emitter) { Emitter.new }
  let(:defined_events) { [:one, :two, :three] }
  
  context 'external api' do
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
        Emitter.emits.should eq defined_events
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
        
        describe '.arity_for_event' do
          it 'reports the arity requirement for the event, if any' do
            Emitter.emits(:jigger, arity: 5)
            Emitter.arity_for_event(:jigger).should eq 5
            Emitter.emits(:pingpong)
            Emitter.arity_for_event(:pingpong).should eq -1        
            Emitter.arity_for_event(:nonevent).should eq nil
          end
        end
      end
    end
    
    it 'allows event registration with lambda' do
      emitter.on(:start, lambda{ puts 'hi' })
    end
    
    it 'allows event registration with proc' do
      emitter.on(:start, proc{ puts 'hi' })
    end
    
    it 'allows event registration with block' do
      emitter.on(:start) do
        puts 'hi'
      end
    end
    
    it 'allows event registration with detached method' do
      def event_handler; end
      emitter.on(:start, method(:event_handler))
    end
    
    it 'allows multiple registrations for a given event' do
      emitter.on(:start) { puts 'hello' }
      emitter.on(:start) { puts 'world' }
    end
  end
  
  context 'when emitting events' do    
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
    
    it 'raises an error when a given callback is invalid' do
      expect { emitter.on(:start, nil, &nil)  }.should raise_error(/Cannot register callback/)
      expect { emitter.on(:start, 10_000)     }.should raise_error(/Cannot register callback/)
      expect { emitter.on(:start, "callback") }.should raise_error(/Cannot register callback/)
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
      it 'accepts a callback with matching arity' do
        Emitter.emits(:hello_world, arity: 2)
        expect {
          emitter.on(:hello_world) do |param1, param2|
            #not invoked
          end
        }.should_not raise_error
      end
      
      it 'rejects a callback if the given arity is not exact' do
        Emitter.emits(:hello_world, arity: 2)
        expect {
          emitter.on(:hello_world) do |param1, param2, param3|
            #not invoked
          end
        }.should raise_error(/Invalid callback arity for event :hello_world \(expected 2, received 3\)/)
      end
    end
  end
end