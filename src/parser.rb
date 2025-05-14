require_relative 'common'

module Nodes
  Definitions = Struct.new(:source_location, :items)
  FunctionDefinition = Struct.new(:source_location, :name, :formal_args, :body)
  Statements = Struct.new(:source_location, :items)
  FunctionCall = Struct.new(:source_location, :name, :actual_args)
  VariableDeclaration = Struct.new(:source_location, :name)
  VariableAssignment = Struct.new(:source_location, :name, :expression)
  VariableReference = Struct.new(:source_location, :name)
  BinaryOperator = Struct.new(:source_location, :glyph, :lhs, :rhs)
  IntegerLiteral = Struct.new(:source_location, :value)
  IfElse = Struct.new(:source_location, :condition, :true_body, :false_body)
  While = Struct.new(:source_location, :condition, :body)
end

class Parser
  include Nodes

  class ParseError < CodeError
  end

  def initialize(tokens)
    @tokens = tokens
  end

  def parse
    parse_definitions
  end

  protected

  def consume(type)
    token = @tokens.shift
    raise ParseError.new(token.source_location, "Expected token type #{type}, but got #{token.type}") unless token.type == type
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

    Definitions.new(nil, items)
  end

  def parse_function_definition
    keyword = consume(:fun)
    name = consume(:identifier).value
    consume(:opening_paren)
    args = parse_formal_arguments
    consume(:closing_paren)
    body = parse_statements

    FunctionDefinition.new(keyword.source_location, name, args, body)
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
    token = consume(:opening_brace)
    items = []
    items << parse_statement until peek(:closing_brace)
    consume(:closing_brace)
    Statements.new(token.source_location, items)
  end

  def parse_statement
    if peek(:if)
      parse_if
    elsif peek(:while)
      parse_while
    elsif peek(:var)
      parse_variable_declaration
    elsif peek(:identifier) && peek(:equals, 1)
      parse_variable_assignment
    else
      parse_expression
    end
  end

  def parse_if
    keyword = consume(:if)
    consume(:opening_paren)
    condition = parse_expression
    consume(:closing_paren)

    true_body = parse_statements
    false_body = if peek(:else)
      consume(:else)
      parse_statements
    end

    IfElse.new(keyword.source_location, condition, true_body, false_body)
  end

  def parse_while
    keyword = consume(:while)
    consume(:opening_paren)
    condition = parse_expression
    consume(:closing_paren)

    body = parse_statements

    While.new(keyword.source_location, condition, body)
  end

  def parse_variable_declaration
    consume(:var)
    name = consume(:identifier)

    VariableDeclaration.new(name.source_location, name.value)
  end

  def parse_variable_assignment
    name = consume(:identifier)
    consume(:equals)
    expression = parse_expression

    VariableAssignment.new(name.source_location, name.value, expression)
  end

  def parse_function_call
    name = consume(:identifier)
    consume(:opening_paren)
    args = parse_actual_arguments
    consume(:closing_paren)

    FunctionCall.new(name.source_location, name.value, args)
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
      raise ParseError.new(@tokens.first.source_location, "Unexpected token found: #{@tokens.first}")
    end

    if peek(:binary_operator)
      operator = consume(:binary_operator)
      BinaryOperator.new(operator.source_location, operator.value, expression, parse_expression)
    else
      expression
    end
  end

  def parse_variable_reference
    name = consume(:identifier)
    VariableReference.new(name.source_location, name.value)
  end

  def parse_integer_literal
    literal = consume(:integer)
    IntegerLiteral.new(literal.source_location, literal.value.to_i)
  end
end
