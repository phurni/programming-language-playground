module Nodes
  Statements = Struct.new(:items)
end

class Parser
  include Nodes

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

  def peek(type)
    @tokens.fetch(0).type == type
  end

  def parse_function_definition
    consume(:fun)
    name = consume(:identifier).value
    consume(:opening_paren)
    args = parse_formal_arguments
    consume(:closing_paren)
    body = parse_statements
  end

  def parse_formal_arguments
    args = []
    if peek(:identifier)
      args << consume(:identifier).value
      while peek(:comma)
        consume(:comma)
        args << consume(:identifier).value
      end
    end
    args
  end

  def parse_statements
    consume(:opening_brace)
    consume(:closing_brace)
    Statements.new([])
  end
end
