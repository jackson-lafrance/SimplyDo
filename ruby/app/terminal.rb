require 'io/console'

module Terminal
  RESET = "\e[0m"
  SELECTED = "\e[1;32m"
  ERROR = "\e[1;47;31m"

  class << self
    def clear_console
      puts "\e]H\e[2J"
    end

    def get_input(description, condition, error = 'ERROR! Please try again!')
      loop do
        puts description
        input = gets.chomp

        return input if condition.call(input)

        puts "#{ERROR} #{error} #{RESET}"
      end
    end

    def find_width
      size = term_size
      if size.nil?
        puts 'CANT FIND TERMINAL SIZE'
        return 80
      end
      while size[0] < 80
        clear_console
        puts 'TERMINAL TOO SMALL'
      end

      size[0]
    end

    private

    def command_exists?(command)
      ENV['PATH'].split(File::PATH_SEPARATOR).any? { |d| File.exist? File.join(d, command) }
    end

    def term_size
      if (ENV['COLUMNS'] =~ /^\d+$/) && (ENV['LINES'] =~ /^\d+$/)
        [ENV['COLUMNS'].to_i, ENV['LINES']]
      elsif (RUBY_PLATFORM =~ /java/ || (~$stdin.tty? && ENV['TERM'])) && command_exists?('tput')
        [`tput cols`.to_i, `tput lines`.to_i]
      elsif $stdin.tty? && command_exists?('stty')
        `stty size`.scan(/\d+/).map(&:to_i).reverse
      end
    end
  end
end
