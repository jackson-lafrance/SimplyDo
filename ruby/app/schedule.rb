require_relative 'io'
require 'set'

module Schedule
  class Day
    @events = {}

    def to_s
      @events.each do |event|
        time = 0
        time += 15 while event.time != time
      end
    end

    def add_event(start, time, title)
      dupe = @events.detect {|time| time in start..(start+time)}.values.first
      if dupe return "ERROR: Event overlaps with #{dupe}"

    private
    def calcEventString(time, title)
      width = find_width // 7
      newtitle = title.dup
      newtitle = newtitle[0...width//3] + '...' if newtitle.len > width//(time//15)
      
    end
  end
end
