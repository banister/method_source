module MethodSource

  module CodeHelpers
    # Retrieve the first expression starting on the given line of the given file.
    #
    # This is useful to get module or method source code.
    #
    # @param [Array<String>, File, String] file  The file to parse, either as a File or as
    # @param [Fixnum]  line_number  The line number at which to look.
    #                             NOTE: The first line in a file is line 1!
    # @param [Boolean]  strict  If set to true, then only completely valid expressions are
    #                         returned. Otherwise heuristics are used to extract
    #                         expressions that may have been valid inside an eval.
    # @return [String]  The first complete expression
    # @raise [SyntaxError]  If the first complete expression can't be identified
    def expression_at(file, line_number, strict=false)
      lines = file.is_a?(Array) ? file : file.each_line.to_a

      relevant_lines = lines[(line_number - 1)..-1] || []

      extract_first_expression(relevant_lines)
    rescue SyntaxError => e
      raise if strict

      begin
        extract_first_expression(relevant_lines) do |code|
          code.gsub(/\#\{.*?\}/, "temp")
        end
      rescue SyntaxError => e2
        raise e
      end
    end

    # Retrieve the comment describing the expression on the given line of the given file.
    #
    # This is useful to get module or method documentation.
    #
    # @param [Array<String>, File, String] file  The file to parse, either as a File or as
    #                                            a String or an Array of lines.
    # @param [Fixnum]  line_number  The line number at which to look.
    #                             NOTE: The first line in a file is line 1!
    # @return [String]  The comment
    def comment_describing(file, line_number)
      lines = file.is_a?(Array) ? file : file.each_line.to_a

      extract_last_comment(lines[0..(line_number - 2)])
    end

    # Determine if a string of code is a complete Ruby expression.
    # @param [String] code The code to validate.
    # @return [Boolean] Whether or not the code is a complete Ruby expression.
    # @raise [SyntaxError] Any SyntaxError that does not represent incompleteness.
    # @example
    #   complete_expression?("class Hello") #=> false
    #   complete_expression?("class Hello; end") #=> true
    #   complete_expression?("class 123") #=> SyntaxError: unexpected tINTEGER
    def complete_expression?(str)
      old_verbose = $VERBOSE
      $VERBOSE = nil

      catch(:valid) do
        eval("BEGIN{throw :valid}\n#{str}")
      end

      # Assert that a line which ends with a , or \ is incomplete.
      str !~ /[,\\]\s*\z/
    rescue IncompleteExpression
      false
    ensure
      $VERBOSE = old_verbose
    end

    private

    # Get the first expression from the input.
    #
    # @param [Array<String>]  lines
    # @param [&Block]  a clean-up function to run before checking for complete_expression
    # @return [String]  a valid ruby expression
    # @raise [SyntaxError]
    def extract_first_expression(lines, &block)
      code = ""
      lines.each do |v|
        code << v
        return code if complete_expression?(block ? block.call(code) : code)
      end
      raise SyntaxError, "unexpected $end"
    end

    # Get the last comment from the input.
    #
    # @param [Array<String>]  lines
    # @return [String]
    def extract_last_comment(lines)
      buffer = ""

      lines.each do |line|
        # Add any line that is a valid ruby comment,
        # but clear as soon as we hit a non comment line.
        if (line =~ /^\s*#/) || (line =~ /^\s*$/)
          buffer << line.lstrip
        else
          buffer.replace("")
        end
      end

      buffer
    end

    # An exception matcher that matches only subsets of SyntaxErrors that can be
    # fixed by adding more input to the buffer.
    module IncompleteExpression
      def self.===(ex)
        case ex.message
        when /unexpected (\$end|end-of-file|END_OF_FILE)/, # mri, jruby, ironruby
          /unterminated (quoted string|string|regexp) meets end of file/, # "quoted string" is ironruby
          /missing 'end' for/, /: expecting '[})\]]'$/, /can't find string ".*" anywhere before EOF/, /: expecting keyword_end/, /expecting kWHEN/ # rbx
          true
        else
          false
        end
      end
    end
  end
end
