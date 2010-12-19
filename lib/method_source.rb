# (C) John Mair (banisterfiend) 2010
# MIT License

direc = File.dirname(__FILE__)

require "#{direc}/method_source/version"

if RUBY_VERSION =~ /1.9/
  require 'ripper'
end

module MethodSource

  # Helper method used to find end of method body
  # @param [String] code The string of Ruby code to check for
  # correctness
  # @return [Boolean] 
  def self.valid_expression?(code)
    !!Ripper::SexpBuilder.new(code).parse
  end

  # Helper method responsible for extracting method body.
  # Defined here to avoid polluting `Method` class.
  # @param [Array] source_location The array returned by Method#source_location
  # @return [File] The opened source file
  def self.source_helper(source_location)
    return nil if !source_location.is_a?(Array)
    
    file_name, line = source_location
    File.open(file_name) do |file|
      (line - 1).times { file.readline }

      code = ""
      loop do
        val = file.readline
        code << val
        
        return code if valid_expression?(code)
      end
    end    
  end
  
  # Helper method responsible for opening source file and buffering up
  # the comments for a specified method. Defined here to avoid polluting 
  # `Method` class.
  # @param [Array] source_location The array returned by Method#source_location
  # @return [String] The comments up to the point of the method.
  def self.comment_helper(source_location)
    return nil if !source_location.is_a?(Array)
    
    file_name, line = source_location
    File.open(file_name) do |file|
      buffer = ""
      (line - 1).times do
        line = file.readline
        # Add any line that is a valid ruby comment, 
        # but clear as soon as we hit a non comment line.
        if (line =~ /^\s*#/) || (line =~ /^\s*$/)
          buffer << line.lstrip
        else
          buffer.clear
        end
      end
      
      buffer
    end
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
      if respond_to?(:source_location)
        source = MethodSource.source_helper(source_location)
        
        raise "Cannot locate source for this method: #{name}" if !source
      else
        raise "Method#source not supported by this Ruby version (#{RUBY_VERSION})"
      end
      
      source
    end
    
    # Return the comments associated with the method as a string.
    # (This functionality is only supported in Ruby 1.9 and above)
    # @return [String] The method's comments as a string
    # @example
    #  Set.instance_method(:clear).comment.display
    #  =>
    #     # Removes all elements and returns self.
    def comment
      if respond_to?(:source_location)
        comment = MethodSource.comment_helper(source_location)
        
        raise "Cannot locate source for this method: #{name}" if !comment
      else
        raise "Method#comment not supported by this Ruby version (#{RUBY_VERSION})"
      end

      comment
    end
  end
end

class Method
  include MethodSource::MethodExtensions
end

class UnboundMethod
  include MethodSource::MethodExtensions
end

class Proc
  include MethodSource::MethodExtensions
end
