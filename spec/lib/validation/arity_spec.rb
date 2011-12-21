require 'spec_helper'
require 'eventually/validation/arity'

unless defined?(ArityEmitter)
  class ArityEmitter
    include Eventually
    emits :started, arity: 1
    emits :stopped
  end
end

describe Eventually::Validation::Arity do
  let(:emitter) { ArityEmitter.new }
  
  describe '#valid?' do
    context 'when arity defined for event' do
      context 'and arity does not match' do
        subject { Eventually::Validation::Arity.new(:started, emitter, 2) }
        it 'is invalid' do
          subject.valid?.should eq false
          subject.expected.should eq 1
          subject.received.should eq 2
        end
      end
      context 'and arity matches' do
        subject { Eventually::Validation::Arity.new(:started, emitter, 1) }
        it 'is valid' do
          subject.valid?.should eq true
          subject.expected.should eq 1
          subject.received.should eq 1
        end
      end
    end
    context 'when event is defined' do
      context 'and arity is not defined' do
        subject { Eventually::Validation::Arity.new(:stopped, emitter, 3) }
        it 'is valid' do
          subject.valid?.should eq true
          subject.expected.should eq -2
          subject.received.should eq 3
        end
      end
    end
    context 'when event is not defined' do
      context 'and arity is not defined' do
        subject { Eventually::Validation::Arity.new(:something_else, emitter, 3) }
        it 'is valid' do
          subject.valid?.should eq true
          subject.expected.should eq nil
          subject.received.should eq 3
        end
      end
    end
  end
  
  describe '#raise_unless_valid!' do
    subject { Eventually::Validation::Arity.new(:an_event, emitter, 0)}
    
    context 'when not valid' do
      it 'does not raise an error' do
        subject.stub(:valid?).and_return(true)
        expect { subject.raise_unless_valid! }.should_not raise_error
      end
    end
    
    context 'when not valid' do
      it 'raises an error' do
        subject.stub(:valid?).and_return(false)
        expect { subject.raise_unless_valid! }.should raise_error
      end
    end
  end
end