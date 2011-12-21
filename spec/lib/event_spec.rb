require 'spec_helper'
require 'eventually/event'

describe Eventually::Event do
  let(:event_name) { :started }
  let(:callable) { Eventually::Callable.new(lambda{}, nil) }
  
  subject { Eventually::Event.new(event_name) }
  its(:name) { should eq event_name }
  its(:emittable?) { should be_true }
  its(:callables) { should be_instance_of(Array) }
  its(:callables) { should be_empty }
  
  describe '#add_callable' do
    it 'adds a callable object to the callables array' do
      subject.add_callable(callable)
      subject.callables.should eq [callable]
    end
    
    it 'skips adding invalid callable objects to callables array' do
      subject.add_callable(nil)
      subject.add_callable(1)
      subject.add_callable("hello, world")
      subject.callables.should be_empty
    end
    
    context 'when event is not emittable' do
      it 'raises an error' do
        evt = Eventually::Event.new(event_name, false)
        expect { evt.add_callable(callable) }.to raise_error(/Event type :#{event_name} will not be emitted\./)
      end
    end
  end
  
  describe '#remove_callable' do
    it 'removes raw callable' do
      evt = Eventually::Event.new(event_name)
      raw_callable = lambda{}
      callable = Eventually::Callable.new(raw_callable, nil)
      evt.add_callable(callable)
      evt.callables.should have(1).item
      evt.remove_callable(raw_callable)
      evt.callables.should be_empty
    end
    
    it 'removes wrapped raw callable' do
      evt = Eventually::Event.new(event_name)
      callable = Eventually::Callable.new(lambda{}, nil)
      evt.add_callable(callable)
      evt.callables.should have(1).item
      evt.remove_callable(callable)
      evt.callables.should be_empty
    end
  end
  
  describe '#remove_all_callables' do
    it 'clears out all registered callables' do
      evt = Eventually::Event.new(event_name)
      evt.add_callable(Eventually::Callable.new(lambda{}, nil))
      evt.add_callable(Eventually::Callable.new(lambda{}, nil))
      evt.add_callable(Eventually::Callable.new(lambda{}, nil))
      evt.add_callable(Eventually::Callable.new(lambda{}, nil))
      evt.add_callable(Eventually::Callable.new(lambda{}, nil))
      evt.callables.should have(5).items
      evt.remove_all_callables
      evt.callables.should be_empty
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
    
    context 'when some callables are one-time callable' do
      it 'removes the one-time callable callables from the callables list' do
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
        evt.callables.should have(5).items
        evt.emit(:data)
        evt.callables.should have(2).items
      end
    end
  end
  
end