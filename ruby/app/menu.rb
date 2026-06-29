require_relative 'io'

module Menu
  class << self
    def menu(index, description, items)
      clear_console
      puts description
      items.each_with_index do |item, i|
        puts "#{index == i ? SELECTED : RESET}- #{item} #{RESET}"
      end
    end

    def use_menu(index, description, items)
      menu(index, description, items)

      items << 'Quit'

      loop do
        char = $stdin.getch
        case char
        when "\e"
          if $stdin.getch == '['
            arrow = $stdin.getch
            index -= 1 if index.positive? && arrow == 'A'
            index += 1 if index < items.length - 1 && arrow == 'B'
          end
        when "\r", "\n"
          return items[index]
        when "\u0003"
          exit
        end
        menu(index, description, items)
      end
    end
  end
end
