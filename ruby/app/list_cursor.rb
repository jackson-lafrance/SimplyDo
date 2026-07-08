class ListCursor
  attr_reader :index

  def initialize(items = [], index: 0)
    @items = []
    @index = 0
    reset(items, index: index)
  end

  def reset(items, index: @index)
    @items = items
    @index = clamp(index)
  end

  def move_up
    @index = clamp(@index - 1)
  end

  def move_down
    @index = clamp(@index + 1)
  end

  def selected
    @items[@index]
  end

  private

  def clamp(index)
    return 0 if @items.empty?

    [[index, 0].max, @items.length - 1].min
  end
end
