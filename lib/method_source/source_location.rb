module MethodSource
  module SourceLocation
    module MethodExtensions

      def trace_func(event, file, line, id, binding, classname)
        return unless event == 'call'
        set_trace_func nil 
        
        @file, @line = file, line
        raise :found
      end

      private :trace_func
      
      # Return the source location of a method for Ruby 1.8.
      # @return [Array] A two element array. First element is the
      #   file, second element is the line in the file where the
      #   method definition is found.
      def source_location
        if @file.nil?
          args =[*(1..(arity<-1 ? -arity-1 : arity ))]
          
          set_trace_func method(:trace_func).to_proc
          call *args rescue nil
          set_trace_func nil 
          @file = File.expand_path(@file) if @file && File.exist?(File.expand_path(@file))
        end
        return [@file, @line] if File.exist?(@file.to_s)
      end
    end

    module UnboundMethodExtensions

      # Return the source location of an instance method for Ruby 1.8.
      # @return [Array] A two element array. First element is the
      #   file, second element is the line in the file where the
      #   method definition is found.
      def source_location
        klass = case owner
                when Class
                  owner
                when Module
                  method_owner = owner
                  Class.new { include(method_owner) }
                end

        begin
          klass.allocate.method(name).source_location
        rescue TypeError

          # Assume we are dealing with a Singleton Class:
          # 1. Get the instance object
          # 2. Forward the source_location lookup to the instance
          instance ||= ObjectSpace.each_object(owner).first
          instance.method(name).source_location
        end
      end
    end
  end
end
