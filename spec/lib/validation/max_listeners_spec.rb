require 'spec_helper'
require 'eventually/validation/max_listeners'

unless defined?(MaxListenerEmitter)
  class MaxListenerEmitter
    include Eventually
  end
end

describe Eventually::Validation::MaxListeners do
  let(:emitter) { MaxListenerEmitter.new }
  subject { Eventually::Validation::MaxListeners.new(emitter) }

  describe '#valid?' do
    context 'when max_listeners is non-zero positive integer' do
      context 'when num_listeners is less than or equal to max_listeners' do
        it 'is valid' do
          emitter.class.max_listeners = 5
          5.times{|i| emitter.on("event"+i.to_s, lambda{}) }
          subject.valid?.should eq true
        end
      end
      context 'when num_listeners is greater than max_listeners' do
        it 'is not valid' do
          emitter.class.max_listeners = 3
          5.times{|i| emitter.on("event"+i.to_s, lambda{}) }
          subject.valid?.should eq false
        end
      end
    end
    context 'when max_listeners is zero' do
      it 'is valid' do
        emitter.class.max_listeners = 0
        1000.times{|i| emitter.on("event"+i.to_s, lambda{}) }
        subject.valid?.should eq true
      end
    end
  end
  
  describe '#warn_unless_valid!' do
    context 'when not valid' do
      it 'does not raise an error' do
        subject.stub(:valid?).and_return(true)
        $stdout.should_not_receive(:puts)
        subject.warn_unless_valid!
      end
    end
    
    context 'when not valid' do
      it 'raises an error' do
        subject.stub(:valid?).and_return(false)
        $stdout.should_receive(:puts).with(/Warning: MaxListenerEmitter has more than \d+ registered listeners\./)
        subject.warn_unless_valid!
      end
    end
  end
end