module InputMask
  TEMPLATES = {
    date: '00/00/00',
    time: '00:00',
    duration: '00:00'
  }.freeze

  State = Struct.new(:type, :digits, :cursor, keyword_init: true)

  class << self
    def build(type, value = '')
      count = slot_count(type)
      State.new(
        type: type,
        digits: normalized_digits(value, count),
        cursor: 0
      )
    end

    def display(state, placeholder: '0')
      state = normalize!(state)
      format_with(state, placeholder)
    end

    def value(state)
      state = normalize!(state)
      return '' if blank?(state)

      format_with(state, '_')
    end

    def input_digit(state, digit)
      state = normalize!(state)
      return unless digit.to_s.match?(/\A\d\z/)
      return if state.cursor >= slot_count(state.type)

      state.digits[state.cursor] = digit
      state.cursor += 1
    end

    def backspace(state)
      state = normalize!(state)
      return if state.cursor.zero?

      state.cursor -= 1
      state.digits[state.cursor] = nil
    end

    def move_cursor(state, amount)
      state = normalize!(state)
      state.cursor = [[state.cursor + amount, 0].max, slot_count(state.type)].min
    end

    def cursor_template_index(state)
      state = normalize!(state)
      positions = slot_positions(state.type)
      return template(state.type).length if state.cursor >= positions.length

      positions[state.cursor]
    end

    def complete?(state)
      normalize!(state).digits.none?(&:nil?)
    end

    def blank?(state)
      normalize!(state).digits.all?(&:nil?)
    end

    private

    def normalize!(state)
      count = slot_count(state.type)
      state.digits = state.digits.to_a.first(count)
      state.digits << nil while state.digits.length < count
      state.cursor = [[state.cursor || 0, 0].max, count].min
      state
    end

    def normalized_digits(value, count)
      digits = value.to_s.scan(/\d/).first(count)
      digits << nil while digits.length < count
      digits
    end

    def format_with(state, placeholder)
      digits = state.digits.dup
      template(state.type).chars.map do |char|
        char == '0' ? (digits.shift || placeholder) : char
      end.join
    end

    def template(type)
      TEMPLATES.fetch(type)
    end

    def slot_count(type)
      slot_positions(type).length
    end

    def slot_positions(type)
      template(type).chars.each_index.select { |index| template(type)[index] == '0' }
    end
  end
end
