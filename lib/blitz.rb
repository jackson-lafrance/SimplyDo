# frozen_string_literal: true

require "io/console"

module Blitz
  extend self
  @screen = nil
  @old_screen = nil

  def check_reset
    reset_screen unless @screen && @screen.length == get_height && @screen[0].length == get_width
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
    if matrix.is_a?(String)
      matrix.each_char.with_index { |letter, col_number| @screen[top][left + col_number] = letter }
    else
      matrix.each_with_index { |row, row_number| row.each_with_index { |letter, col_number| @screen[top + row_number][left + col_number] = letter } }
    end
  end

  def create_screen
    print "\033[2J\033[H"
    height.times do |h|
      width.times do |w|
        next if @screen[h][w] == @old_screen[h][w]

        print "\033[#{h + 1};#{w + 1}H"
        print @screen[h][w] || " "
      end
      print "\n"
    end
    @old_screen = @screen.map(&:dup)
  end

  def get_ch
    loop do
      char = $stdin.getch
      case char
      when "\e"
        if $stdin.getch == "["
          arrow = $stdin.getch
          return "LEFT" if arrow == "D"
          return "RIGHT" if arrow == "C"
          return "UP" if arrow == "A"
          return "DOWN" if arrow == "B"
        end
      when "\r", "\n"
        return "CR"
      when "\u0003"
        exit
      else return char
      end
    end
  end

  private

  def safe_text(str)
    str
      .encode("ASCII", invalid: :replace, undef: :replace, replace: "?")
  end

  def reset_screen
    @screen = Array.new(get_height) { Array.new(get_width) }
    @old_screen = Array.new(get_height) { Array.new(get_width) }
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
  end

  def get_width
    size = detect_terminal_size
    raise StandardError, "Could not compute terminal size" unless size
    size[0]
  end

  def get_height
    size = detect_terminal_size
    raise StandardError, "Could not compute terminal size" unless size
    size[1]
  end

  def command_exists?(command)
    system("command -v #{command} > /dev/null 2>&1")
  end
end
