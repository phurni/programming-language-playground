class Tokenizer
  TOKEN_TYPES = [
    [:fun, /\bfun\b/],
    [:var, /\bvar\b/],
    [:if, /\bif\b/],
    [:else, /\belse\b/],

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

  Token = Struct.new(:type, :value)

  def initialize(code)
    @code = code.strip
    @tokens = []
  end

  def tokenize
    until @code.empty?
      @tokens << find_token
      @code.lstrip!
    end
    @tokens
  end

  protected

  def find_token
    TOKEN_TYPES.each do |type, re|
      if value = @code.slice!(/\A(#{re})/)
        return Token.new(type, value.strip)
      end
    end

    raise RuntimeError.new("Could not match token near: #{@code[/.*/]}")
  end
end
