require_relative 'common'

class Interpreter
  include Nodes

  class RuntimeError < CodeError
  end

  def initialize
    @functions = {}
    add_primitives
  end

  def run(node, context)
    case node
    when Definitions
      node.items.each {|item| run(item, context) }

    when FunctionDefinition
      raise RuntimeError.new("Trying to redefine function: #{node.name}") if @functions.has_key?(node.name)
      @functions[node.name] = node

    when Statements
      node.items.reduce(nil) {|last_value, item| run(item, context) }

    when FunctionCall
      function_node = @functions[node.name]
      raise RuntimeError.new("Trying to call unknown function #{node.name}") unless function_node
      raise RuntimeError.new("Calling function #{node.name} with #{node.actual_args.size} arguments when #{function_node.formal_args.size} needed") unless node.actual_args.size == function_node.formal_args.size

      new_context = function_node.formal_args.zip(node.actual_args.map {|arg| run(arg, context) }).to_h
      run(function_node.body, new_context)

    when IfElse
      if run(node.condition, context)
        run(node.true_body, context)
      else
        run(node.false_body, context) if node.false_body
      end

    when While
      while run(node.condition, context)
        run(node.body, context)
      end

    when VariableDeclaration
      context[node.name] = nil

    when VariableAssignment
      raise RuntimeError.new("Trying to assign undeclared variable #{node.name}") unless context.has_key?(node.name)
      context[node.name] = run(node.expression, context)

    when VariableReference
      raise RuntimeError.new("Trying to reference undeclared variable #{node.name}") unless context.has_key?(node.name)
      context[node.name]

    when IntegerLiteral
      node.value

    when BinaryOperator
      lhs = run(node.lhs, context)
      rhs = run(node.rhs, context)

      case node.glyph
      when '*'  then lhs * rhs
      when '/'  then lhs / rhs
      when '%'  then lhs % rhs
      when '+'  then lhs + rhs
      when '-'  then lhs - rhs

      when '<'  then lhs < rhs
      when '<=' then lhs <= rhs
      when '>'  then lhs > rhs
      when '>=' then lhs >= rhs
      when '==' then lhs == rhs
      when '!=' then lhs == rhs

      else
        raise RuntimeError.new("Unknown operator #{node.glyph}")
      end

    when Proc
      node.call(context)

    else
      raise RuntimeError.new("Unexpected node type: #{node.class}")
    end
  end

  protected

  def add_primitives
    @functions['print'] = FunctionDefinition.new(nil, 'print', ['value'], lambda {|context| puts context['value'] })
  end
end
