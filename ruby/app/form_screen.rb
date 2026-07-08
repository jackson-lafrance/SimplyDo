require_relative 'constants'
require_relative 'input_mask'
require_relative 'list_cursor'
require_relative 'screen_buffer'
require_relative 'terminal'

class FormScreen
  Field = Struct.new(:key, :label, :value, :type, :hidden_if, :edited, :mask_state, keyword_init: true)

  def initialize(title:, fields:, submit_label:, &on_submit)
    @title = title
    @fields = fields
    @submit_label = submit_label
    @on_submit = on_submit
    @cursor = ListCursor.new(visible_items)
    @error = nil
    @invalid_key = nil
  end

  def show
    Terminal.hide_cursor

    loop do
      sync_cursor
      render

      key = Terminal.read_key
      return if key.nil? || key == :escape

      selected = @cursor.selected
      if selected == :submit
        result = submit
        return result if result
      else
        handle_field_key(selected, key)
      end
    end
  end

  private

  def handle_field_key(field, key)
    clear_error

    case key
    when :up
      @cursor.move_up
    when :down, :enter
      @cursor.move_down
    when :left
      masked_field?(field) ? move_mask_cursor(field, -1) : adjust(field, -1)
    when :right
      masked_field?(field) ? move_mask_cursor(field, 1) : adjust(field, 1)
    when :shift_left
      masked_field?(field) ? move_mask_cursor(field, -1) : adjust(field, -30)
    when :shift_right
      masked_field?(field) ? move_mask_cursor(field, 1) : adjust(field, 30)
    when :backspace
      backspace(field)
    else
      write_character(field, key) if Terminal.printable_key?(key)
    end
  end

  def write_character(field, key)
    return if field.type == :toggle

    if masked_field?(field)
      InputMask.input_digit(mask_state(field), key)
      field.edited = true
      return
    end

    field.value = field.edited ? "#{field.value}#{key}" : key
    field.edited = true
  end

  def backspace(field)
    if masked_field?(field)
      InputMask.backspace(mask_state(field))
    else
      field.value = field.value.to_s[0...-1]
    end

    field.edited = true
  end

  def adjust(field, amount)
    case field.type
    when :number
      field.value = [field.value.to_i + (amount.negative? ? -1 : 1), 1].max.to_s
      field.edited = true
    when :choice, :toggle
      toggle(field)
    end
  end

  def toggle(field)
    case field.type
    when :toggle
      field.value = field.value == 'yes' ? 'no' : 'yes'
    when :choice
      field.value = field.value == 'days' ? 'weeks' : 'days'
    end
    field.edited = true
  end

  def move_mask_cursor(field, amount)
    InputMask.move_cursor(mask_state(field), amount)
  end

  def masked_field?(field)
    %i[date time duration].include?(field.type)
  end

  def mask_state(field)
    field.mask_state ||= InputMask.build(field.type, field.value)
  end

  def field_value(field)
    return InputMask.value(mask_state(field)) if masked_field?(field)

    field.value
  end

  def submit
    result = @on_submit.call(values)
    return result if result[:ok]

    @error = result[:error]
    @invalid_key = result[:field]
    move_to_invalid_field
    nil
  end

  def values
    @fields.to_h { |field| [field.key, field_value(field)] }
  end

  def visible_fields
    current_values = values
    @fields.reject { |field| field.hidden_if&.call(current_values) }
  end

  def visible_items
    visible_fields + [:submit]
  end

  def sync_cursor
    @cursor.reset(visible_items)
  end

  def move_to_invalid_field
    field = visible_fields.find { |visible_field| visible_field.key == @invalid_key }
    return unless field

    @cursor.reset(visible_items, index: visible_items.index(field))
  end

  def render
    buffer = ScreenBuffer.new(width: Terminal.width, height: Terminal.height)
    buffer.write(0, 0, @title, color: Constants::Terminal::TITLE)

    selected_mask = nil
    y = 2
    visible_fields.each do |field|
      selected = @cursor.selected.equal?(field)
      invalid = @invalid_key == field.key
      draw_field(buffer, y, field, selected: selected, invalid: invalid)
      selected_mask = [field, y] if selected && masked_field?(field)
      y += 2
    end

    draw_submit(buffer, y)
    draw_footer(buffer)
    Terminal.blit(buffer)
    selected_mask ? move_cursor_to_mask(*selected_mask) : Terminal.hide_cursor
  end

  def draw_field(buffer, y, field, selected:, invalid:)
    label_color = if invalid
                    Constants::Terminal::ERROR
                  elsif selected
                    Constants::Terminal::SELECTED
                  end
    value_color = if invalid
                    Constants::Terminal::ERROR
                  elsif selected
                    Constants::Terminal::USER_INPUT
                  end

    buffer.write(0, y, selected ? '>' : ' ')
    buffer.write(2, y, field.label, color: label_color)
    buffer.write(18, y, display_value(field), color: value_color)
  end

  def move_cursor_to_mask(field, y)
    Terminal.show_cursor
    x = 18 + InputMask.cursor_template_index(mask_state(field))
    print "\e[#{y + 1};#{x + 1}H"
  end

  def draw_submit(buffer, y)
    selected = @cursor.selected == :submit
    color = selected ? Constants::Terminal::SELECTED : Constants::Terminal::PRIMARY_ACTION

    buffer.write(0, y, selected ? '>' : ' ')
    buffer.write(2, y, @submit_label, color: color)
  end

  def draw_footer(buffer)
    footer_y = [Terminal.height - 4, 0].max
    buffer.write_control_line(0, footer_y, '[↑/↓] Field  [type] Edit  [←/→] Move mask/adjust  [shift ←/→] ±30')
    buffer.write_control_line(0, footer_y + 1, '[enter] Next/submit  [esc] Back')
    buffer.write(0, footer_y + 2, @error.to_s, color: Constants::Terminal::ERROR) if @error
  end

  def display_value(field)
    case field.type
    when :date, :time, :duration
      InputMask.display(mask_state(field))
    when :choice, :number
      "‹ #{field.value} ›"
    else
      field.value.to_s
    end
  end

  def clear_error
    @error = nil
    @invalid_key = nil
  end

end
