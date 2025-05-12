class Parser
  def initialize(tokens)
    @tokens = tokens
  end

  def parse
    parse_function_definition
  end

  protected

  def consume(type)
    token = @tokens.shift
    raise RuntimeError.new("Expected token type #{type}, but got #{token.type}\nNext tokens: #{@tokens.first(5)}") unless token.type == type
    token
  end

  def parse_function_definition
  end
end
