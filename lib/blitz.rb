# frozen_string_literal: true

module Blitz
  @screen = nil
  @old_screen = nil

  def check_reset
    @screen = @old_screen
    reset_screen unless @screen && @screen.length == get_height
  end

  def width
    raise StandardError, "No Screen defined" unless @screen
    @screen[0].length
  end

  def height
    raise StandardError, "No Screen defined" unless @screen
    @screen.length
  end

  def blit(top, left, matrix)
    if matrix.is_a?(string)
      matrix.for_each_with_index { |letter, col_number| @screen[top][left + col_number] = letter }
    else
      matrix.for_each_with_index { |row, row_number| row.for_each_with_index { |letter, col_number| @screen[top + row_number][left + col_number] = letter } }
    end
  end

  def create_screen
    print "\e[H"
    height.times do |h|
      width.times do |w|
        print @screen[h][w] unless @screen[h][w] == @old_screen[h][w]
      end
      print "\n"
    end
  end

  private

  def safe_text(str)
    str
      .encode("ASCII", invalid: :replace, undef: :replace, replace: "?")
  end

  def reset_screen
    @screen = Array.new(get_height) { Array.new(get_width) }
    @old_screen = nil
  end

  def detect_terminal_size
    if (ENV['COLUMNS'] =~ /^\d+$/) && (ENV['LINES'] =~ /^\d+$/)
      [ENV['COLUMNS'].to_i, ENV['LINES'].to_i]
    elsif (RUBY_PLATFORM =~ /java/ || (!STDIN.tty? && ENV['TERM'])) && command_exists?('tput')
      [`tput cols`.to_i, `tput lines`.to_i]
    elsif STDIN.tty? && command_exists?('stty')
      `stty size`.scan(/\d+/).map { |s| s.to_i }.reverse
    else
      nil
    end
  rescue
    nil
  end

  def get_width
    w = detect_terminal_size[0]
    raise StandardError, "Could not compute terminal size" unless w
    w
  end

  def get_height
    h = detect_terminal_size[1]
    raise StandardError, "Could not compute terminal size" unless h
    h
  end
end
