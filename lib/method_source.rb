# (C) John Mair (banisterfiend) 2010
# MIT License

direc = File.dirname(__FILE__)

require 'stringio'
require "#{direc}/method_source/version"

module MethodSource

  # Helper method used to find end of method body
  # @param [String] code The string of Ruby code to check for
  # correctness
  # @return [Boolean] 
  def self.valid_expression?(code)
    suppress_stderr do
      RubyVM::InstructionSequence.new(code)
    end
  rescue Exception
    false
  else
    true
  end

  # Helper method used to suppress stderr output by the
  # `RubyVM::InstructionSequence` method
  # @yield The block where stderr is suppressed
  def self.suppress_stderr
    real_stderr, $stderr = $stderr, StringIO.new
    yield
  ensure
    $stderr = real_stderr
  end

  # Helper method responsible for opening source file and advancing to
  # the correct linenumber. Defined here to avoid polluting `Method`
  # class.
  # @param [Array] source_location The array returned by Method#source_location
  # @return [File] The opened source file
  def self.source_helper(source_location)
    return nil if !source_location.is_a?(Array)
    
    file_name, line = source_location
    file = File.open(file_name)
    (line - 1).times { file.readline }
    file
  end
  
  # This module is to be included by `Method` and `UnboundMethod` and
  # provides the `#source` functionality
  module MethodExtensions
    
    # Return the sourcecode for the method as a string
    # (This functionality is only supported in Ruby 1.9 and above)
    # @return [String] The method sourcecode as a string
    # @example
    #  Set.instance_method(:clear).source.display
    #  =>
    #     def clear
    #       @hash.clear
    #       self
    #     end
    def source
      file = nil
      
      if respond_to?(:source_location)
        file = MethodSource.source_helper(source_location)
        
        raise "Cannot locate source for this method: #{name}" if !file
      else
        raise "Method#source not supported by this Ruby version (#{RUBY_VERSION})"
      end

      code = ""
      loop do
        val = file.readline
        code += val
        
        return code if MethodSource.valid_expression?(code)
      end
      
    ensure
      file.close if file
    end
  end
end

class Method
  include MethodSource::MethodExtensions
end

class UnboundMethod
  include MethodSource::MethodExtensions
end
