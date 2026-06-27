require "io/console"

module Menu
  class << self
    RESET = "\e[0m"
    SELECTED = "\e[1;32m"
    ERROR = "\e[1;47;31m"

    def clear_console = puts "\e]H\e[2J"

    def menu(index, description, items)
      clear_console
      puts description
      items.each_with_index do |item, i|
          puts "#{index == i ? CS : CR}- #{item} #{CR}"
      end
    end

    def use_menu(index, description, items)
      menu(index, description, items)

      loop do
        char = $stdin.getch
        case char
        when "\e"
          if $stdin.getch == "["
            arrow = $stdin.getch
            index -= 1 if index.positive? && arrow == "A"
            index += 1 if index < items.length - 1 && arrow == "B"
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

Menu.menu(1,"Hello",["ee","eeee","ee"])

module Menu
  class << self
    RESET = "\e[0m"
    SELECTED = "\e[1;32m"
    ERROR = "\e[1;47;31m"

    def clear_console = puts "\e]H\e[2J"

    def menu(index, description, items)
      clear_console
      puts description
      items.each_with_index do |item, i|
          puts "#{index == i ? CS : CR}- #{item} #{CR}"
      end
    end

    def use_menu(index, description, items)
      menu(index, description, items)

      loop do
        char = $stdin.getch
        case char
        when "\e"
          if $stdin.getch == "["
            arrow = $stdin.getch
            index -= 1 if index.positive? && arrow == "A"
            index += 1 if index < items.length - 1 && arrow == "B"
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

Menu.menu(1,"Hello",["ee","eeee","ee"])

module Menu
  class << self
    RESET = "\e[0m"
    SELECTED = "\e[1;32m"
    ERROR = "\e[1;47;31m"

    def clear_console = puts "\e]H\e[2J"

    def menu(index, description, items)
      clear_console
      puts description
      items.each_with_index do |item, i|
          puts "#{index == i ? CS : CR}- #{item} #{CR}"
      end
    end

    def use_menu(index, description, items)
      menu(index, description, items)

      loop do
        char = $stdin.getch
        case char
        when "\e"
          if $stdin.getch == "["
            arrow = $stdin.getch
            index -= 1 if index.positive? && arrow == "A"
            index += 1 if index < items.length - 1 && arrow == "B"
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

Menu.menu(1,"Hello",["ee","eeee","ee"])
