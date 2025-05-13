module Nodes
  Definitions = Struct.new(:items)
  FunctionDefinition = Struct.new(:name, :formal_args, :body)
  Statements = Struct.new(:items)
  FunctionCall = Struct.new(:name, :actual_args)
  VariableReference = Struct.new(:name)
  BinaryOperator = Struct.new(:glyph, :lhs, :rhs)
  IntegerLiteral = Struct.new(:value)
  IfElse = Struct.new(:condition, :true_body, :false_body)
end

class Parser
  include Nodes

  def initialize(tokens)
    @tokens = tokens
  end

  def parse
    parse_definitions
  end

  protected

  def consume(type)
    token = @tokens.shift
    raise RuntimeError.new("Expected token type #{type}, but got #{token.type}\nNext tokens: #{@tokens.first(5)}") unless token.type == type
    token
  end

  def peek(type, offset = 0)
    @tokens.fetch(offset).type == type
  end

  def empty?
    @tokens.empty?
  end

  def parse_definitions
    items = []
    items << parse_function_definition until empty?

    Definitions.new(items)
  end

  def parse_function_definition
    consume(:fun)
    name = consume(:identifier).value
    consume(:opening_paren)
    args = parse_formal_arguments
    consume(:closing_paren)
    body = parse_statements

    FunctionDefinition.new(name, args, body)
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
    items = []
    items << parse_statement until peek(:closing_brace)
    consume(:closing_brace)
    Statements.new(items)
  end

  def parse_statement
    if peek(:if)
      parse_if
    elsif peek(:identifier) && peek(:opening_paren, 1)
      parse_function_call
    else
      raise RuntimeError.new("Unexpected token found: #{@tokens.first(5)}")
    end
  end

  def parse_if
    consume(:if)
    consume(:opening_paren)
    condition = parse_expression
    consume(:closing_paren)

    true_body = parse_statements
    false_body = if peek(:else)
      consume(:else)
      parse_statements
    end

    IfElse.new(condition, true_body, false_body)
  end

  def parse_function_call
    name = consume(:identifier)
    consume(:opening_paren)
    args = parse_actual_arguments
    consume(:closing_paren)

    FunctionCall.new(name.value, args)
  end

  def parse_actual_arguments
    args = []
    if !peek(:closing_paren)
      args << parse_expression
      while peek(:comma)
        consume(:comma)
        args << parse_expression
      end
    end
    args
  end

  def parse_expression
    expression = if peek(:integer)
      parse_integer_literal
    elsif peek(:identifier) && peek(:opening_paren, 1)
      parse_function_call
    elsif peek(:identifier)
      parse_variable_reference
    else
      raise RuntimeError.new("Unexpected token found: #{@tokens.first(5)}")
    end

    if peek(:binary_operator)
      operator = consume(:binary_operator)
      BinaryOperator.new(operator.value, expression, parse_expression)
    else
      expression
    end
  end

  def parse_variable_reference
    VariableReference.new(consume(:identifier).value)
  end

  def parse_integer_literal
    IntegerLiteral.new(consume(:integer).value.to_i)
  end
end
