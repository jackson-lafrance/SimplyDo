require_relative 'constants'
require_relative 'screen_buffer'
require_relative 'terminal'

module Menu
  class << self
    def menu(index, description, items)
      Terminal.hide_cursor

      buffer = ScreenBuffer.new(width: Terminal.width, height: Terminal.height)
      buffer.write(0, 0, description, color: Constants::Terminal::TITLE)

      items.each_with_index do |item, i|
        color = index == i ? Constants::Terminal::SELECTED : nil
        buffer.write(0, i + 2, "- #{item}", color: color)
      end

      Terminal.blit(buffer)
    end

    def use_menu(index, description, items, include_quit: true)
      options = include_quit ? items + ['Quit'] : items.dup
      menu(index, description, options)

      loop do
        key = Terminal.read_key
        exit if key.nil?

        case key
        when :up
          index -= 1 if index.positive?
        when :down
          index += 1 if index < options.length - 1
        when :enter
          return options[index]
        end

        menu(index, description, options)
      end
    end
  end
end
