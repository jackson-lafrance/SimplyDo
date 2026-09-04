# typed: true
# frozen_string_literal: true

require "io/console"
require "sorbet-runtime"

module Blitz
  extend T::Sig
  extend self
  include Kernel

  @screen = T.let(nil, T.nilable(T::Array[T::Array[T.nilable(String)]]))
  @old_screen = T.let(nil, T.nilable(T::Array[T::Array[T.nilable(String)]]))

  sig { void }
  def check_reset
    screen = @screen
    reset_screen unless screen && screen.length == get_height && screen.first&.length == get_width
  end

  sig { returns(Integer) }
  def width
    screen = @screen
    raise StandardError, "No Screen defined" unless screen
    screen.fetch(0).length
  end

  sig { returns(Integer) }
  def height
    screen = @screen
    raise StandardError, "No Screen defined" unless screen
    screen.length
  end

  sig { params(top: Integer, left: Integer, matrix: T.any(String, T::Array[T::Array[String]])).void }
  def blit(top, left, matrix)
    screen = @screen
    raise StandardError, "No Screen defined" unless screen

    if matrix.is_a?(String)
      matrix.each_char.with_index { |letter, col_number| screen.fetch(top)[left + col_number] = letter }
    else
      matrix.each_with_index do |row, row_number|
        row.each_with_index { |letter, col_number| screen.fetch(top + row_number)[left + col_number] = letter }
      end
    end
  end

  sig { void }
  def create_screen
    screen = @screen
    old_screen = @old_screen
    raise StandardError, "No Screen defined" unless screen && old_screen

    height.times do |h|
      width.times do |w|
        next if screen.fetch(h).fetch(w) == old_screen.fetch(h).fetch(w)

        print "\033[#{h + 1};#{w + 1}H"
        print screen.fetch(h).fetch(w) || " "
      end
    end

    @old_screen = screen.map(&:dup)
    $stdout.flush
  end

  sig { returns(String) }
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

  sig { params(str: String).returns(String) }
  def safe_text(str)
    str
      .encode("ASCII", invalid: :replace, undef: :replace, replace: "?")
  end

  sig { void }
  def reset_screen
    @screen = Array.new(get_height) { Array.new(get_width) }
    @old_screen = Array.new(get_height) { Array.new(get_width) }
    print "\033[2J\033[H"
  end

  sig { returns(T.nilable(T::Array[Integer])) }
  def detect_terminal_size
    if (ENV['COLUMNS'] =~ /^\d+$/) && (ENV['LINES'] =~ /^\d+$/)
      [ENV['COLUMNS'].to_i, ENV['LINES'].to_i]
    elsif (RUBY_PLATFORM =~ /java/ || (!STDIN.tty? && ENV['TERM'])) && command_exists?('tput')
      [`tput cols`.to_i, `tput lines`.to_i]
    elsif STDIN.tty? && command_exists?('stty')
      `stty size`.split.map(&:to_i).reverse
    else
      nil
    end
  end

  sig { returns(Integer) }
  def get_width
    size = detect_terminal_size
    raise StandardError, "Could not compute terminal size" unless size
    T.must(size).fetch(0)
  end

  sig { returns(Integer) }
  def get_height
    size = detect_terminal_size
    raise StandardError, "Could not compute terminal size" unless size
    T.must(size).fetch(1)
  end

  sig { params(command: String).returns(T::Boolean) }
  def command_exists?(command)
    !!system("command -v #{command} > /dev/null 2>&1")
  end
end
