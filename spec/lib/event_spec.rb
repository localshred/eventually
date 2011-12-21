require 'spec_helper'
require 'eventually/event'

describe Eventually::Event do
  let(:event_name) { :started }
  let(:callable) { Eventually::Callable.new(lambda{}, nil) }
  
  subject { Eventually::Event.new(event_name) }
  its(:name) { should eq event_name }
  its(:emittable?) { should be_true }
  its(:listeners) { should be_instance_of(Array) }
  its(:listeners) { should be_empty }
  
  describe '.add_callable' do
    it 'adds a callable object to the listeners array' do
      subject.add_callable(callable)
      subject.listeners.should eq [callable]
    end
    
    it 'skips adding invalid callable objects to listeners array' do
      subject.add_callable(nil)
      subject.add_callable(1)
      subject.add_callable("hello, world")
      subject.listeners.should be_empty
    end
    
    context 'when event is not emittable' do
      it 'raises an error' do
        evt = Eventually::Event.new(event_name, false)
        expect { evt.add_callable(callable) }.to raise_error(/Event type :#{event_name} will not be emitted\./)
      end
    end
  end
  
  describe '#emit' do
    context 'when not emittable' do
      it 'raises an error' do
        evt = Eventually::Event.new(event_name, false)
        expect { evt.emit(:data) }.to raise_error(/Event type :#{event_name} cannot be emitted\./)
      end
    end

    it 'calls each listener callback' do
      evt = Eventually::Event.new(event_name)
      cbs = [
        Eventually::Callable.new(lambda{}, nil),
        Eventually::Callable.new(lambda{}, nil),
        Eventually::Callable.new(lambda{}, nil),
        Eventually::Callable.new(lambda{}, nil),
        Eventually::Callable.new(lambda{}, nil)
      ]
      cbs.each do |cb|
        evt.add_callable(cb)
        cb.should_receive(:call).once.with(:data)
      end
      evt.emit(:data)
    end
    
    context 'when some listeners are one-time callable' do
      it 'removes the one-time callable listeners from the listeners list' do
        evt = Eventually::Event.new(event_name)
        cbs = [
          Eventually::Callable.new(lambda{}, nil),
          Eventually::Callable.new(lambda{}, nil, :once),
          Eventually::Callable.new(lambda{}, nil, :once),
          Eventually::Callable.new(lambda{}, nil, :once),
          Eventually::Callable.new(lambda{}, nil)
        ]
        cbs.each do |cb|
          evt.add_callable(cb)
          cb.should_receive(:call).once.with(:data)
        end
        evt.listeners.should have(5).items
        evt.emit(:data)
        evt.listeners.should have(2).items
      end
    end
  end
  
end