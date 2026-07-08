require_relative 'constants'

class ScreenBuffer
  attr_reader :width, :height

  def initialize(width:, height:)
    @width = width
    @height = height
    @chars = Array.new(height) { Array.new(width, ' ') }
    @colors = Array.new(height) { Array.new(width) }
  end

  def write(x, y, text, color: nil)
    return if y.negative? || y >= height || x >= width

    text.to_s.each_char.with_index do |char, index|
      cell_x = x + index
      next if cell_x.negative?
      break if cell_x >= width

      @chars[y][cell_x] = char
      @colors[y][cell_x] = color
    end
  end

  def write_segments(x, y, segments)
    cursor_x = x

    segments.each do |text, color|
      text = text.to_s
      write(cursor_x, y, text, color: color)
      cursor_x += text.length
    end
  end

  def write_control_line(x, y, text)
    segments = text.to_s.scan(/\[[^\]]+\]|[^\[]+/).map do |segment|
      color = segment.start_with?('[') ? Constants::Terminal::KEY_HINT : Constants::Terminal::TOOLTIP_TEXT
      [segment, color]
    end

    write_segments(x, y, segments)
  end

  def box(x, y, width, height, title: nil, color: nil)
    return if width < 2 || height < 2

    write(x, y, top_border(width, title), color: color)
    (1...(height - 1)).each { |offset| write(x, y + offset, "│#{' ' * (width - 2)}│", color: color) }
    write(x, y + height - 1, "└#{'─' * (width - 2)}┘", color: color)
  end

  def to_s
    @chars.each_with_index.map { |row, y| render_row(row, @colors[y]) }.join("\n")
  end

  private

  def render_row(row, colors)
    active_color = nil
    rendered = +''

    row.each_with_index do |char, x|
      color = colors[x]
      if color != active_color
        rendered << Constants::Terminal::RESET if active_color
        rendered << color.to_s if color
        active_color = color
      end

      rendered << char
    end

    rendered << Constants::Terminal::RESET if active_color
    rendered
  end

  def top_border(width, title)
    return "┌#{'─' * (width - 2)}┐" if title.nil? || title.empty?

    title = " #{title} "
    remaining = width - title.length - 2
    "┌#{title}#{'─' * [remaining, 0].max}┐"[0...width]
  end
end
