require_relative 'common'

class Interpreter
  include Nodes

  class RuntimeError < CodeError
  end

  class CompilationError < CodeError
  end

  def initialize
    @functions = {}
    add_primitives
  end

  def compile(node)
    case node
    when Definitions
      node.items.each {|item| compile(item) }

    when FunctionDefinition
      raise CompilationError.new(node.source_location, "Trying to redefine function: #{node.name}") if @functions.has_key?(node.name)
      node.body = compile(node.body)
      @functions[node.name] = node

    when Statements
      nodes = node.items.map {|item| compile(item) }
      nodes.each_cons(2) {|first, second| first.next = second }
      nodes.first

    when FunctionCall
      new_node = promote_node(node)
      new_node.actual_args = node.actual_args.map {|arg| compile(arg) }
      new_node

    when VariableDeclaration, VariableReference, IntegerLiteral
      promote_node(node)

    else
      raise CompilationError.new("Unexpected node type: #{node.class}")
    end
  end

  def run(node, context)
    value = nil
    next_node = node

    while next_node
      node = next_node
      next_node = node.next

      case node
      when FunctionCall
        function_node = @functions[node.name]
        raise RuntimeError.new(node.source_location, "Trying to call unknown function #{node.name}") unless function_node
        raise RuntimeError.new(node.source_location, "Calling function #{node.name} with #{node.actual_args.size} arguments when #{function_node.formal_args.size} needed") unless node.actual_args.size == function_node.formal_args.size

        new_context = function_node.formal_args.zip(node.actual_args.map {|arg| run(arg, context) }).to_h
        run(function_node.body, new_context)

      when VariableDeclaration
        context[node.name] = nil

      when VariableAssignment
        raise RuntimeError.new(node.source_location, "Trying to assign undeclared variable #{node.name}") unless context.has_key?(node.name)
        context[node.name] = run(node.expression, context)

      when VariableReference
        raise RuntimeError.new(node.source_location, "Trying to reference undeclared variable #{node.name}") unless context.has_key?(node.name)
        value = context[node.name]

      when IntegerLiteral
        value = node.value

      when BinaryOperator
        lhs = run(node.lhs, context)
        rhs = run(node.rhs, context)

        value = case node.glyph
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
          raise RuntimeError.new(node.source_location, "Unknown operator #{node.glyph}")
        end

      when Proc
        value = node.call(context)

      else
        raise RuntimeError.new("Unexpected node type: #{node.class}")
      end
    end

    value
  end

  protected

  def add_primitives
    @functions['print'] = FunctionDefinition.new(nil, 'print', ['value'], promote_node(lambda {|context| puts context['value'] }))
  end

  module NodeLink
    attr_accessor :next
  end

  def promote_node(node)
    node.extend(NodeLink)
  end
end
