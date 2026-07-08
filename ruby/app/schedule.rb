require 'date'
require_relative 'constants'

module Schedule
  Event = Struct.new(:id, :day, :start, :time, :title, :recurring_event_id, :deleted_at, keyword_init: true) do
    def finish
      start + time
    end

    def recurring?
      !recurring_event_id.nil?
    end

    def deleted?
      !deleted_at.nil?
    end
  end

  RecurringEvent = Struct.new(:id, :starts_on, :ends_on, :unit, :interval, :start, :time, :title, :deleted_at, keyword_init: true) do
    def deleted?
      !deleted_at.nil?
    end
  end

  DeletedOccurrence = Struct.new(:recurring_event_id, :day, :deleted_at, keyword_init: true)

  @events = []
  @recurring_events = []
  @deleted_occurrences = []
  @next_event_id = 1
  @next_recurring_event_id = 1

  class << self
    def add_event(day, start, time, title)
      event = Event.new(
        id: next_event_id,
        day: normalize_day(day),
        start: start,
        time: time,
        title: title,
        recurring_event_id: nil,
        deleted_at: nil
      )

      @events << event
      event
    end

    def add_recurring_event(starts_on:, unit:, interval:, start:, time:, title:, ends_on: nil)
      recurring_event = RecurringEvent.new(
        id: next_recurring_event_id,
        starts_on: normalize_day(starts_on),
        ends_on: ends_on.nil? ? nil : normalize_day(ends_on),
        unit: normalize_unit(unit),
        interval: normalize_interval(interval),
        start: start,
        time: time,
        title: title,
        deleted_at: nil
      )

      @recurring_events << recurring_event
      recurring_event
    end

    def remove_event(id, deleted_at: Time.now)
      event = event(id)
      return if event.nil? || event.deleted?

      event.deleted_at = deleted_at
      event
    end

    def remove_recurring_event(id, deleted_at: Time.now)
      recurring_event = recurring_event(id)
      return if recurring_event.nil? || recurring_event.deleted?

      recurring_event.deleted_at = deleted_at
      recurring_event
    end

    def remove_recurring_occurrence(recurring_event_id, day, deleted_at: Time.now)
      day = normalize_day(day)
      existing = @deleted_occurrences.find do |deleted_occurrence|
        deleted_occurrence.recurring_event_id == recurring_event_id && deleted_occurrence.day == day
      end
      return existing if existing

      deleted_occurrence = DeletedOccurrence.new(
        recurring_event_id: recurring_event_id,
        day: day,
        deleted_at: deleted_at
      )

      @deleted_occurrences << deleted_occurrence
      deleted_occurrence
    end

    def event(id)
      @events.find { |existing| existing.id == id }
    end

    def recurring_event(id)
      @recurring_events.find { |existing| existing.id == id }
    end

    def events_for(day)
      day = normalize_day(day)
      one_time_events = @events.select { |event| !event.deleted? && event.day == day }
      recurring_events = @recurring_events
        .select { |recurring_event| recurring_event_on?(recurring_event, day) }
        .map { |recurring_event| event_from_recurring_event(recurring_event, day) }

      sort_events(one_time_events + recurring_events)
    end

    def parse_duration(input)
      text = input.to_s.strip
      raise ArgumentError, 'duration cannot be blank' if text.empty?
      raise ArgumentError, 'duration must look like HH:MM' unless text.match?(/\A\d{2}:\d{2}\z/)

      hours, minutes = text.split(':').map(&:to_i)
      (hours * 60) + minutes
    end

    def format_time(minutes)
      format('%02d:%02d', minutes / 60, minutes % 60)
    end

    def format_duration(minutes)
      hours = minutes / 60
      remaining_minutes = minutes % 60
      parts = []

      parts << "#{hours} h" if hours.positive?
      parts << "#{remaining_minutes} min" if remaining_minutes.positive?
      parts.empty? ? '0 min' : parts.join(' ')
    end

    private

    def next_event_id
      id = @next_event_id
      @next_event_id += 1
      id
    end

    def next_recurring_event_id
      id = @next_recurring_event_id
      @next_recurring_event_id += 1
      id
    end

    def sort_events(events)
      events.sort_by { |event| [event.start, event.finish, event.title] }
    end

    def normalize_day(day)
      return day if day.is_a?(Date)

      Date.parse(day.to_s)
    end

    def normalize_unit(unit)
      unit = unit.to_s.downcase.to_sym
      raise ArgumentError, "repeat type must be one of #{Constants::Schedule::RECURRING_UNITS.join(', ')}" unless Constants::Schedule::RECURRING_UNITS.include?(unit)

      unit
    end

    def normalize_interval(interval)
      interval = interval.to_i
      raise ArgumentError, 'interval must be at least 1' if interval < 1

      interval
    end

    def recurring_event_on?(recurring_event, day)
      return false if recurring_event.deleted?
      return false if occurrence_deleted?(recurring_event.id, day)
      return false if day < recurring_event.starts_on
      return false if recurring_event.ends_on && day > recurring_event.ends_on

      days_between = (day - recurring_event.starts_on).to_i
      repeat_every = recurring_event.unit == :weeks ? recurring_event.interval * 7 : recurring_event.interval
      (days_between % repeat_every).zero?
    end

    def occurrence_deleted?(recurring_event_id, day)
      @deleted_occurrences.any? do |deleted_occurrence|
        deleted_occurrence.recurring_event_id == recurring_event_id && deleted_occurrence.day == day
      end
    end

    def event_from_recurring_event(recurring_event, day)
      Event.new(
        id: "recurring-#{recurring_event.id}-#{day.iso8601}",
        day: day,
        start: recurring_event.start,
        time: recurring_event.time,
        title: recurring_event.title,
        recurring_event_id: recurring_event.id,
        deleted_at: nil
      )
    end
  end
end
