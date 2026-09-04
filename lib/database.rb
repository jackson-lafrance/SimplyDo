# frozen_string_literal: true

require "sqlite3"

module Database
  def init_database
    @db = SQLite3::Database.new("data.db")
    @db.results_as_hash = true
    @db.execute "CREATE TABLE IF NOT EXISTS Bookings(id INTEGER NOT NULL PRIMARY KEY, color INTEGER, title TEXT NOT NULL, description TEXT, start_date TEXT, length INTEGER,
times INTEGER, type TEXT)"
    @db.execute "CREATE TABLE IF NOT EXISTS Tasks(id INTEGER NOT NULL PRIMARY KEY, color INTEGER, title TEXT NOT NULL, description TEXT, due_date TEXT)"
  end

  def get_time
    check_connection
    @db.execute "SELECT datetime('now','localtime')"
  end

  def get_tasks
    check_connection
    @db.execute "SELECT * FROM Tasks"
  end

  def get_bookings
    check_connection
    @db.execute "SELECT * FROM Bookings"
  end

  def make_task(task)
    check_connection
    db.execute "INSERT INTO Tasks (title, description, color, start_date, length, times, type) VALUES (?, ?, ?, ?, ?, ?, ?)",
      task[:title], task[:description], task[:color], task[:start_date], task[:length], task[:times], task[:type]
  end

  def make_booking(booking)
    check_connection
    db.execute "INSERT INTO Bookings (title, description, color, due_date) VALUES (?, ?, ?, ?)",
      booking[:title], booking[:description], booking[:color], booking[:due_date]
  end

  private

  def check_connection
    raise StandardError, "No database found" unless @db
  end
end
