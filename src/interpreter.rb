class Interpreter
  include Nodes

  def initialize
  end

  def run(node, context)
    case node
    when Definitions
      node.items.each {|item| run(item, context) }
    end
  end
end
