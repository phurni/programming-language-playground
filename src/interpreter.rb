class Interpreter
  include Nodes

  class RuntimeError < StandardError
  end

  def initialize
    @functions = {}
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

    else
      raise RuntimeError.new("Unexpected node type: #{node.class}")
    end
  end
end
