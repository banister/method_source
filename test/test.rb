direc = File.dirname(__FILE__)

require 'bacon'
require "#{direc}/../lib/method_source"

hello_source = "def hello; :hello; end\n"
lambda_source = "MyLambda = lambda { :lambda }\n"
proc_source = "MyProc = Proc.new { :proc }\n"

def hello; :hello; end

MyLambda = lambda { :lambda }
MyProc = Proc.new { :proc }

describe MethodSource do
  it 'should define methods on Method and UnboundMethod and Proc' do
    Method.method_defined?(:source).should == true
    UnboundMethod.method_defined?(:source).should == true
    Proc.method_defined?(:source).should == true
  end

  describe "Methods" do
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

  describe "Lambdas and Procs" do
    if RUBY_VERSION =~ /1.9/
      it 'should return source for proc' do
        MyProc.source.should == proc_source
      end

      it 'should return source for lambda' do
        MyLambda.source.should == lambda_source
      end
    else
      it 'should raise on #source' do
        lambda { method(:hello).source }.should.raise RuntimeError
      end
    end      
  end
end
