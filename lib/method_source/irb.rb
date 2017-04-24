# From the gem "cute_print", and before that from the gem "wrong"

if defined? IRB
  module IRB
    class Context

      def source
        @all_lines.join
      end

      original_evaluate = instance_method(:evaluate)

      # Save every line that is evaluated.  This gives a way to get
      # the source when it is run in irb.
      define_method :evaluate do |src, line_no|
        @all_lines ||= []
        @all_lines += ["\n"] * (line_no - @all_lines.size - 1)
        @all_lines += src.lines.to_a
        original_evaluate.bind(self).call src, line_no
      end

    end
  end
end
