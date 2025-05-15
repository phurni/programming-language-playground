require_relative 'common'

class Interpreter
  include Nodes

  class RuntimeError < CodeError
  end

  class StackOverflowError < RuntimeError
  end

  class CompilationError < CodeError
  end

  def initialize(stack_max_depth: 1000)
    @stack_max_depth = stack_max_depth
    @stack = []
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
      node.body.last_next = compile(FunctionReturn.new(node.body.source_location, IntegerLiteral.new(node.body.source_location, 0)))
      @functions[node.name] = node

    when Statements
      nodes = node.items.map {|item| compile(item) }
      nodes.each_cons(2) {|first, second| first.next = second }
      nodes.first

    when FunctionCall
      new_node = promote_node(node)
      new_node.actual_args = node.actual_args.map {|arg| compile(arg) }
      new_node

    when FunctionReturn
      new_node = promote_node(node)
      new_node.expression = compile(node.expression)
      new_node

    when VariableAssignment
      new_node = promote_node(node)
      new_node.expression = compile(node.expression)
      new_node

    when BinaryOperator
      new_node = promote_node(node)
      new_node.lhs = compile(node.lhs)
      new_node.rhs = compile(node.rhs)
      new_node

    when VariableDeclaration, VariableReference, IntegerLiteral
      promote_node(node)

    when IfElse
      new_node = promote_node(node)
      new_node.condition = compile(node.condition)
      new_node.true_body = compile(node.true_body)
      new_node.false_body = compile(node.false_body) if node.false_body
      def new_node.next=(target)
        self.false_body.last_next = target if self.false_body
        self.true_body.last_next = target
        @next = target
      end
      new_node

    when While
      new_node = promote_node(node)
      new_node.condition = compile(node.condition)
      new_node.body = compile(node.body)
      new_node.body.last_next = new_node
      new_node

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
        raise StackOverflowError.new(node.source_location, "Stack max depth reached (#{@stack_max_depth}) when calling function #{node.name}") if @stack.size > @stack_max_depth

        function_node = @functions[node.name]
        raise RuntimeError.new(node.source_location, "Trying to call unknown function #{node.name}") unless function_node
        raise RuntimeError.new(node.source_location, "Calling function #{node.name} with #{node.actual_args.size} arguments when #{function_node.formal_args.size} needed") unless node.actual_args.size == function_node.formal_args.size

        new_context = function_node.formal_args.zip(node.actual_args.map {|arg| run(arg, context) }).to_h
        context['@next'] = node.next
        @stack.push(context)
        context = new_context
        next_node = function_node.body

      when FunctionReturn
        value = run(node.expression, context)
        context = @stack.pop
        next_node = context['@next']

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

      when IfElse
        if run(node.condition, context)
          next_node = node.true_body
        elsif node.false_body
          next_node = node.false_body
        end

      when While
        if run(node.condition, context)
          next_node = node.body
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
    @functions['print'] = FunctionDefinition.new(nil, 'print', ['value'], promote_node(FunctionReturn.new(nil, promote_node(lambda {|context| puts context['value'] }))))
  end

  module NodeLink
    attr_accessor :next

    def last_next=(target)
      last_node = self
      last_node = last_node.next while last_node&.next
      last_node.next = target
    end
  end

  def promote_node(node)
    node.extend(NodeLink)
  end
end
