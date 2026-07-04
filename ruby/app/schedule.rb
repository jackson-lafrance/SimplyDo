require_relative 'terminal'

module Schedule
  class Day
    def initialize
      @events = {}
    end

    def to_s
      return 'No events' if @events.empty?

      @events
        .sort_by { |time_range, _title| time_range.begin }
        .map { |time_range, title| event_string(time_range, title) }
        .join("\n")
    end

    def add_event(start, time, title)
      time_range = start...(start + time)
      dupe = @events.detect { |event_range, _title| overlaps?(event_range, time_range) }&.last

      if dupe
        print "Event overlaps with #{dupe}\nStill add it? (Y / n): "
        return if gets.chomp in ['n', 'N', 'no', 'NO', 'No']
      end

      @events[time_range] = title
    end

    private

    def overlaps?(event_range, new_range)
      new_range.begin < event_range.end && event_range.begin < new_range.end
    end

    def event_string(time_range, title)
      "#{title}: #{format_time(time_range.begin)} - #{format_duration(time_range.end - time_range.begin)}"
    end

    def format_time(minutes)
      format('%02d:%02d', minutes / 60, minutes % 60)
    end

    def format_duration(minutes)
      hours = minutes / 60
      remaining_minutes = minutes % 60
      parts = []

      parts << "#{hours} #{hours == 1 ? 'hour' : 'hours'}" if hours.positive?
      parts << "#{remaining_minutes} #{remaining_minutes == 1 ? 'minute' : 'minutes'}" if remaining_minutes.positive?

      parts.empty? ? '0 minutes' : parts.join(' ')
    end
  end
end
