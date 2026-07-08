require 'date'
require_relative 'constants'
require_relative 'form_screen'
require_relative 'input_mask'
require_relative 'list_cursor'
require_relative 'menu'
require_relative 'schedule'
require_relative 'screen_buffer'
require_relative 'terminal'

module ScheduleScreen
  class << self
    def show
      @current_day = Date.today
      @view = :week
      @day_cursor = ListCursor.new(visible_days, index: @current_day.cwday - 1)
      @event_cursor = ListCursor.new([])
      @message = nil

      loop do
        sync_cursors
        render(message: @message)
        @message = nil

        key = Terminal.read_key
        return if key.nil?

        action = @view == :week ? handle_week_key(key) : handle_day_key(key)
        return if action == :exit
      end
    end

    private

    def handle_week_key(key)
      case key
      when :up
        @day_cursor.move_up
        @current_day = @day_cursor.selected
      when :down
        @day_cursor.move_down
        @current_day = @day_cursor.selected
      when :left
        @current_day -= 7
      when :right
        @current_day += 7
      when :enter
        @view = :day
      when 'e'
        add_event_flow
      when '.'
        @current_day = Date.today
      when '/'
        jump_to_date
      when :escape
        :exit
      end
    end

    def handle_day_key(key)
      case key
      when :up
        @event_cursor.move_up
      when :down
        @event_cursor.move_down
      when :left
        @current_day -= 1
      when :right
        @current_day += 1
      when 'e'
        add_event_flow
      when 'r'
        remove_current_event
      when '.'
        @current_day = Date.today
      when '/'
        jump_to_date
      when :escape
        @view = :week
      end
    end

    def render(message: nil, search_text: nil, search_cursor: nil)
      search_text.nil? ? Terminal.hide_cursor : Terminal.show_cursor

      buffer = ScreenBuffer.new(width: Terminal.width, height: Terminal.height)
      draw_header(buffer)
      draw_schedule(buffer)
      draw_footer(buffer, message: message, search_text: search_text)

      Terminal.blit(buffer)
      move_cursor_to_search(buffer, search_text, search_cursor) unless search_text.nil?
    end

    def draw_header(buffer)
      buffer.write(0, 0, 'Schedule', color: Constants::Terminal::TITLE)
      buffer.write(0, 1, current_range_label, color: Constants::Terminal::SUBTITLE)
    end

    def draw_schedule(buffer)
      y = 3
      max_y = footer_y(buffer) - 1

      if @view == :week
        visible_days.each_with_index do |day, index|
          y = draw_week_day(buffer, y, max_y, day, selected: index == @day_cursor.index)
        end
      else
        draw_day_view(buffer, y, max_y)
      end
    end

    def draw_week_day(buffer, y, max_y, day, selected:)
      return y if y > max_y

      header_color = if selected
                       Constants::Terminal::SELECTED
                     elsif day == Date.today
                       Constants::Terminal::TODAY
                     end

      buffer.write(0, y, "#{selected ? '>' : ' '} #{day.strftime('%A, %b %-d')}", color: header_color)
      y += 1

      events = Schedule.events_for(day)
      if events.empty?
        buffer.write(0, y, '    No events', color: Constants::Terminal::EMPTY_STATE) if y <= max_y
        return y + 1
      end

      events.each do |event|
        return draw_overflow(buffer, y, max_y) if y > max_y

        draw_event_summary(buffer, 4, y, event)
        y += 1
      end

      y
    end

    def draw_day_view(buffer, y, max_y)
      if day_events.empty?
        buffer.write(0, y, '  No events', color: Constants::Terminal::EMPTY_STATE) if y <= max_y
        return y + 1
      end

      day_events.each_with_index do |event, index|
        return draw_overflow(buffer, y, max_y) if y > max_y

        selected = index == @event_cursor.index
        buffer.write(0, y, selected ? '>' : ' ', color: selected ? Constants::Terminal::SELECTED : nil)
        draw_event_summary(buffer, 2, y, event, selected: selected)
        y += 1
      end

      y
    end

    def draw_overflow(buffer, y, max_y)
      buffer.write(0, max_y, '  ...', color: Constants::Terminal::EMPTY_STATE) if max_y.positive?
      y
    end

    def draw_footer(buffer, message:, search_text:)
      footer_y = footer_y(buffer)
      controls = if search_text.nil?
                   controls_line
                 else
                   '[0-9] Type  [←/→] Move  [enter] Jump  [backspace] Delete  [esc] Cancel'
                 end
      buffer.write_control_line(0, footer_y, controls)
      buffer.write(0, footer_y + 1, message.to_s, color: message_color(message)) if message
      draw_search_box(buffer, footer_y + 2, search_text) unless search_text.nil?
    end

    def footer_y(buffer)
      [buffer.height - 5, 0].max
    end

    def draw_search_box(buffer, y, search_text)
      box_width = [[buffer.width, 100].min, 40].max
      box_height = 3
      buffer.box(0, y, box_width, box_height, title: 'Jump to date DD/MM/YY', color: Constants::Terminal::BORDER)

      input_width = box_width - 4
      search_text = search_text.to_s
      visible_text = search_text.length > input_width ? search_text[-input_width..] : search_text
      buffer.write(2, y + 1, visible_text, color: Constants::Terminal::USER_INPUT)
    end

    def move_cursor_to_search(buffer, search_text, search_cursor)
      box_width = [[buffer.width, 100].min, 40].max
      input_width = box_width - 4
      visible_text = search_text.to_s.length > input_width ? search_text.to_s[-input_width..] : search_text.to_s
      cursor = [search_cursor || visible_text.length, visible_text.length].min
      x = 2 + cursor
      y = footer_y(buffer) + 3
      print "\e[#{y + 1};#{x + 1}H"
    end

    def draw_event_summary(buffer, x, y, event, selected: false)
      buffer.write_segments(x, y, event_summary_segments(event, selected: selected))
    end

    def event_summary_segments(event, selected: false)
      segments = [
        [Schedule.format_time(event.start), Constants::Terminal::EVENT_TIME],
        [' ', nil],
        [event.title, selected ? Constants::Terminal::SELECTED : nil]
      ]

      segments << [' ↻', Constants::Terminal::RECURRING] if event.recurring?
      segments << [' - ', Constants::Terminal::SEPARATOR]
      segments << [Schedule.format_duration(event.time), Constants::Terminal::EVENT_DURATION]
      segments
    end

    def message_color(message)
      text = message.to_s
      return Constants::Terminal::ERROR if text.start_with?('Could not')
      return Constants::Terminal::WARNING if text.start_with?('There are no')

      Constants::Terminal::SUCCESS
    end

    def controls_line
      if @view == :week
        '[↑/↓] Day  [enter] Open  [←/→] Week  [e] New  [/] Jump  [.] Today  [esc] Back'
      else
        '[↑/↓] Event  [r] Remove  [e] New  [←/→] Day  [/] Jump  [.] Today  [esc] Week'
      end
    end

    def current_range_label
      if @view == :day
        friendly_date(@current_day, include_year: false)
      else
        start_day = week_start(@current_day)
        end_day = start_day + 6
        "#{friendly_date(start_day)} -> #{friendly_date(end_day)}"
      end
    end

    def friendly_date(day, include_year: true)
      text = "#{day.strftime('%B')} #{ordinal(day.day)}"
      include_year ? "#{text} #{day.year}" : text
    end

    def masked_date(day)
      format('%02d/%02d/%02d', day.day, day.month, day.year % 100)
    end

    def ordinal(number)
      suffix = if (11..13).include?(number % 100)
                 'th'
               else
                 case number % 10
                 when 1 then 'st'
                 when 2 then 'nd'
                 when 3 then 'rd'
                 else 'th'
                 end
               end

      "#{number}#{suffix}"
    end

    def visible_days
      start_day = week_start(@current_day)
      (0...7).map { |offset| start_day + offset }
    end

    def day_events
      Schedule.events_for(@current_day)
    end

    def sync_cursors
      days = visible_days
      selected_day_index = days.index(@current_day) || 0
      @day_cursor.reset(days, index: selected_day_index)
      @event_cursor.reset(day_events)
    end

    def week_start(day)
      day - (day.cwday - 1)
    end

    def add_event_flow
      result = FormScreen.new(title: 'Add event', fields: event_form_fields, submit_label: 'Create event') do |values|
        submit_event_form(values)
      end.show

      return unless result

      @current_day = result[:day]
      @message = 'Event added.'
    end

    def event_form_fields
      recurring_hidden = ->(values) { values[:recurring] != 'yes' }

      [
        FormScreen::Field.new(key: :title, label: 'Title', value: '', type: :text),
        FormScreen::Field.new(key: :date, label: 'Date', value: masked_date(@current_day), type: :date),
        FormScreen::Field.new(key: :start, label: 'Start time', value: default_start_time, type: :time),
        FormScreen::Field.new(key: :duration, label: 'Duration', value: '01:00', type: :duration),
        FormScreen::Field.new(key: :recurring, label: 'Recurring', value: 'no', type: :toggle),
        FormScreen::Field.new(key: :repeat_type, label: 'Repeat type', value: 'days', type: :choice, hidden_if: recurring_hidden),
        FormScreen::Field.new(key: :repeat_every, label: 'Repeat every', value: '1', type: :number, hidden_if: recurring_hidden),
        FormScreen::Field.new(key: :ends_on, label: 'Ends on', value: '', type: :date, hidden_if: recurring_hidden)
      ]
    end

    def submit_event_form(values)
      title = values[:title].to_s.strip
      return form_error(:title, 'Title cannot be blank') if title.empty?

      day = parse_form_date(values[:date], :date)
      start = parse_form_time(values[:start])
      duration = parse_form_duration(values[:duration])
      return day unless day.is_a?(Date)
      return start unless start.is_a?(Integer)
      return duration unless duration.is_a?(Integer)

      if values[:recurring] == 'yes'
        submit_recurring_event(values, title, day, start, duration)
      else
        Schedule.add_event(day, start, duration, title)
        { ok: true, day: day }
      end
    end

    def submit_recurring_event(values, title, day, start, duration)
      interval = values[:repeat_every].to_i
      return form_error(:repeat_every, 'Repeat every must be at least 1') if interval < 1

      ends_on = nil
      unless values[:ends_on].to_s.strip.empty?
        ends_on = parse_form_date(values[:ends_on], :ends_on)
        return ends_on unless ends_on.is_a?(Date)
        return form_error(:ends_on, 'Ends on must be after the event date') if ends_on < day
      end

      Schedule.add_recurring_event(
        starts_on: day,
        unit: values[:repeat_type],
        interval: interval,
        ends_on: ends_on,
        start: start,
        time: duration,
        title: title
      )
      { ok: true, day: day }
    rescue ArgumentError => e
      form_error(:repeat_type, e.message)
    end

    def remove_current_event
      if day_events.empty?
        @message = 'There are no events on this day to remove.'
        return
      end

      remove_selected_event(@event_cursor.selected)
      sync_cursors
    end

    def remove_selected_event(event)
      if event.recurring?
        remove_recurring_event_flow(event)
      elsif Terminal.confirm?("Remove \"#{event.title}\"? y/N: ")
        Schedule.remove_event(event.id)
        @message = 'Event removed.'
      end
    end

    def remove_recurring_event_flow(event)
      choice = Menu.use_menu(
        0,
        "Remove \"#{event.title}\"",
        ['This instance only', 'All occurrences', 'Cancel'],
        include_quit: false
      )

      case choice
      when 'This instance only'
        Schedule.remove_recurring_occurrence(event.recurring_event_id, event.day)
        @message = 'Recurring event instance removed.'
      when 'All occurrences'
        Schedule.remove_recurring_event(event.recurring_event_id)
        @message = 'Recurring event removed.'
      end
    end

    def jump_to_date
      date_input = InputMask.build(:date)
      message = nil

      loop do
        render(
          search_text: InputMask.display(date_input),
          search_cursor: InputMask.cursor_template_index(date_input),
          message: message
        )
        key = Terminal.read_key
        return if key.nil?

        case key
        when :enter
          begin
            @current_day = date_from_mask(InputMask.value(date_input))
            return
          rescue ArgumentError
            message = 'Could not jump: enter a valid date as DD/MM/YY'
          end
        when :left
          InputMask.move_cursor(date_input, -1)
          message = nil
        when :right
          InputMask.move_cursor(date_input, 1)
          message = nil
        when :backspace
          InputMask.backspace(date_input)
          message = nil
        when :escape
          return
        else
          InputMask.input_digit(date_input, key) if Terminal.printable_key?(key)
          message = nil
        end
      end
    end

    def parse_form_date(input, field)
      date_from_mask(input)
    rescue ArgumentError
      form_error(field, "#{input} is not a valid date. Use DD/MM/YY")
    end

    def date_from_mask(input)
      text = input.to_s
      raise ArgumentError unless text.match?(/\A\d{2}\/\d{2}\/\d{2}\z/)

      day, month, year = text.split('/').map(&:to_i)
      Date.new(2000 + year, month, day)
    end

    def parse_form_time(input)
      return form_error(:start, 'Start time must look like HH:MM') unless input.to_s.match?(/\A\d{2}:\d{2}\z/)

      hour, minute = input.split(':').map(&:to_i)
      return form_error(:start, 'Start time minutes must be between 00 and 59') unless minute.between?(0, 59)

      (hour * 60) + minute
    end

    def parse_form_duration(input)
      duration = Schedule.parse_duration(input)
      return form_error(:duration, 'Duration must be longer than 0 minutes') unless duration.positive?

      duration
    rescue ArgumentError => e
      form_error(:duration, e.message)
    end

    def form_error(field, message)
      { ok: false, field: field, error: message }
    end

    def default_start_time
      minutes = if @current_day == Date.today
                  now = Time.now
                  (((now.hour * 60) + now.min + 29) / 30) * 30
                else
                  9 * 60
                end

      Schedule.format_time(minutes % (24 * 60))
    end
  end
end
