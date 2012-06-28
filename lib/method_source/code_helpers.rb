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
      each_expression_guess(lines) do |code|
        return code if complete_expression?(block ? block.call(code) : code)
      end
      raise SyntaxError, "unexpected $end"
    end

    # Guess at which subsets of the entire file might be valid expressions.
    #
    # In the simple case this just iterates over all possible substrings that
    # start on the first line.
    #
    # Unfortunately complete_expression? is an O(n) check, and so this quickly
    # adds up if we're calling it n times. To avoid that in the common case,
    # we assert that people will indent code correctly and do a fast search for
    # the first correctly indented end. If that's not right, we fall back to the
    # simple iteration scheme.
    #
    # TODO: we should strongly consider using a real tokenizer here so that we
    # can get O(n) behaviour more of the time.
    #
    # @param [Array<String>]  lines
    # @yield [String]  a potential ruby expression
    def each_expression_guess(lines)
      begin
        if lines.first =~ /\A([ \t]*)(class|module|def) /
          indent = $1
          code = ""
          lines.each do |v|
            code << v
            yield code if v =~ /\A#{indent}end/
          end
        end
      rescue  SyntaxError => e
        # pass
      end

      code = ""
      lines.each do |v|
        code << v
        yield code
      end
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
