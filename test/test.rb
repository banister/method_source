direc = File.dirname(__FILE__)

require 'bacon'
require "#{direc}/../lib/method_source"

hello_source = "def hello; :hello; end\n"

def hello; :hello; end

describe MethodSource do

  it 'should define methods on both Method and UnboundMethod' do
    Method.method_defined?(:source).should == true
    UnboundMethod.method_defined?(:source).should == true
  end
  
  if RUBY_VERSION =~ /1.9/
    it 'should return source for method' do
      method(:hello).source.should == hello_source
    end

    it 'should raise for C methods' do
      lambda { method(:puts).source }.should.raise RuntimeError
    end

  else
    it 'should raise on #source' do
      lambda { method(:hello).source }.should.raise RuntimeError
    end
  end
end

