require_relative 'common'

class Tokenizer
  class SyntaxError < CodeError
  end

  TOKEN_TYPES = [
    [:fun, /\bfun\b/],
    [:var, /\bvar\b/],
    [:if, /\bif\b/],
    [:else, /\belse\b/],
    [:while, /\bwhile\b/],
    [:return, /\breturn\b/],

    [:identifier, /\b[a-zA-Z_]\w*\b/],
    [:integer, /\b\d+\b/],

    [:binary_operator, /(==|!=|<=|>=|[<>*\/%+-])\s+/],
    [:opening_paren, /\(/],
    [:closing_paren, /\)/],
    [:opening_brace, /\{/],
    [:closing_brace, /\}/],
    [:comma, /,/],
    [:equals, /=/],
  ]

  Token = Struct.new(:source_location, :type, :value)

  def initialize(code, filename = nil)
    @code = code.rstrip
    @tokens = []
    @filename = filename.freeze
    @line_number = 1 + @code.slice!(/\A(\s*)/).count("\n")
  end

  def tokenize
    until @code.empty?
      @tokens << find_token
      @line_number += @code.slice!(/\A(\s*)/).count("\n")
    end
    @tokens
  end

  protected

  def find_token
    TOKEN_TYPES.each do |type, re|
      if value = @code.slice!(/\A(#{re})/)
        return Token.new(SourceLocation.new(@filename, @line_number), type, value.strip)
      end
    end

    raise SyntaxError.new(SourceLocation.new(@filename, @line_number), "Could not match token near: #{@code[/.*/]}")
  end
end
