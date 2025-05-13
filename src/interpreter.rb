class Interpreter
  include Nodes

  class RuntimeError < StandardError
  end

  def initialize
  end

  def run(node, context)
    case node
    when Definitions
      node.items.each {|item| run(item, context) }

    else
      raise RuntimeError.new("Unexpected node type: #{node.class}")
    end
  end
end
