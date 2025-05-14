SourceLocation = Struct.new(:filename, :line_number) do
  def to_s
    "#{filename || '(none)'}:#{line_number}"
  end
end

class CodeError < StandardError
  def initialize(*captions)
    super(captions.compact.join(': '))
  end
end
