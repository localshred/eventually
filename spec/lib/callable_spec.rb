require 'spec_helper'
require 'eventually/callable'

describe Eventually::Callable do
  let(:cb_lambda) { lambda{ :lambda } }
  let(:cb_proc) { proc{ :proc } }
  let(:cb_block) { proc{ :block } }
  let(:cb_method) { def callable_meth; :meth end; method(:callable_meth) }
  let(:availability) { :continuous }
  
  subject { Eventually::Callable.new(cb_lambda, cb_block, availability) }
  its(:callable) { should eq cb_lambda }
  its(:availability) { should eq availability }
  
  context 'when callable arg is' do
    context 'a lambda' do
      subject { Eventually::Callable.new(cb_lambda, nil) }
      its(:callable) { should eq cb_lambda }
    end
    context 'a proc' do
      subject { Eventually::Callable.new(cb_proc, nil) }
      its(:callable) { should eq cb_proc }
    end
    context 'a detached method' do
      subject { Eventually::Callable.new(cb_method, nil) }
      its(:callable) { should eq cb_method }
    end
  end
  
  context 'when callable arg is not valid' do
    context 'and block arg is valid' do
      subject { Eventually::Callable.new(nil, cb_block) }
      its(:callable) { should eq cb_block }
    end
    
    context 'and block arg is valid' do
      it 'raises an error that provided callable(s) were invalid' do
        expect {
          Eventually::Callable.new(nil, nil)
        }.should raise_error(/Cannot register callable\. Neither callable nor block was given\./)
      end
    end
  end
  
  describe '#continuous?' do
    context 'when availability is :continuous' do
      subject { Eventually::Callable.new(cb_lambda, nil, :continuous) }
      its(:availability) { should eq :continuous }
      its(:continuous?) { should be_true }
    end
    
    context 'when availability is :continuous' do
      subject { Eventually::Callable.new(cb_lambda, nil, :once) }
      its(:availability) { should eq :once }
      its(:continuous?) { should be_false }
    end
  end
  
  context 'delegation' do
    it 'delegates :arity to callable' do
      subject.arity.should eq subject.callable.arity
    end
    it 'delegates :call to callable' do
      subject.call.should eq subject.callable.call
    end
    it 'delegates :to_proc to callable' do
      subject.to_proc.should eq subject.callable.to_proc
    end
  end
end