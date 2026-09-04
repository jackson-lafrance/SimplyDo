# frozen_string_literal: true

require_relative "lib/blitz"
require_relative "lib/database"
require_relative "lib/display"

Database.init_database
Database.make_task(
  title: "Database test task",
  description: "Created from main.rb",
  color: nil,
  due_date: nil
)

tasks = Database.get_tasks

Blitz.check_reset
lines = ["Tasks"] + tasks.map { |task| "#{task["id"]}: #{task["title"]}" }
top = [Blitz.height / 2, 0].max

lines.each_with_index do |line, index|
  left = [Blitz.width / 2, 0].max
  Blitz.blit(top + index, left, line)
end

Blitz.create_screen
gets&.chomp
