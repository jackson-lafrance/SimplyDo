require 'io/console'

module Terminal
  class << self
    def clear_console
      print "\e[H\e[2J"
    end

    def hide_cursor
      print "\e[?25l"
    end

    def show_cursor
      print "\e[?25h"
    end

    def blit(buffer)
      clear_console
      print buffer.to_s
    end

    def confirm?(message)
      show_cursor
      print message
      %w[y yes].include?(gets&.chomp.to_s.downcase)
    end

    def printable_key?(key)
      key.is_a?(String) && key.length == 1 && key.ord.between?(32, 126)
    end

    def read_key
      char = read_char
      return if char.nil?

      case char
      when "\e"
        read_escape_sequence
      when "\r", "\n"
        :enter
      when "\u0003"
        exit
      when "\u007F", "\b"
        :backspace
      else
        char
      end
    end

    def width(default: 80)
      terminal_size&.first || default
    end

    def height(default: 24)
      terminal_size&.last || default
    end

    private

    def read_char
      $stdin.getch
    rescue Errno::ENOTTY
      $stdin.read(1)
    end

    def read_escape_sequence
      return :escape unless input_waiting?

      second = read_char
      return :escape unless second == '['

      sequence = +''
      loop do
        char = read_char
        return :escape if char.nil?

        sequence << char
        break if char.match?(/[A-Za-z~]/)
      end

      shift = sequence.include?(';2')
      case sequence[-1]
      when 'A' then shift ? :shift_up : :up
      when 'B' then shift ? :shift_down : :down
      when 'C' then shift ? :shift_right : :right
      when 'D' then shift ? :shift_left : :left
      else :escape
      end
    end

    def input_waiting?
      ::IO.select([$stdin], nil, nil, 0.01)
    rescue StandardError
      false
    end

    def terminal_size
      if ::IO.console
        rows, columns = ::IO.console.winsize
        [columns, rows]
      elsif (ENV['COLUMNS'] =~ /^\d+$/) && (ENV['LINES'] =~ /^\d+$/)
        [ENV['COLUMNS'].to_i, ENV['LINES'].to_i]
      else
        [80, 24]
      end
    rescue StandardError
      [80, 24]
    end
  end
end

at_exit { Terminal.show_cursor }
