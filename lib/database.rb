# typed: true
# frozen_string_literal: true

require "sqlite3"
require "sorbet-runtime"

module Database
  extend T::Sig
  extend self
  include Kernel

  @db = T.let(nil, T.nilable(SQLite3::Database))

  sig { void }
  def init_database
    @db = SQLite3::Database.new("data.db")
    @db.results_as_hash = true
    @db.execute "CREATE TABLE IF NOT EXISTS Bookings(id INTEGER NOT NULL PRIMARY KEY, color INTEGER, title TEXT NOT NULL, description TEXT, start_date TEXT, length INTEGER,
times INTEGER, type TEXT)"
    @db.execute "CREATE TABLE IF NOT EXISTS Tasks(id INTEGER NOT NULL PRIMARY KEY, color INTEGER, title TEXT NOT NULL, description TEXT, due_date TEXT)"
  end

  sig { returns(T::Array[T::Hash[T.untyped, T.untyped]]) }
  def get_time
    check_connection.execute "SELECT datetime('now','localtime')"
  end

  sig { returns(T::Array[T::Hash[T.untyped, T.untyped]]) }
  def get_tasks
    check_connection.execute "SELECT * FROM Tasks"
  end

  sig { returns(T::Array[T::Hash[T.untyped, T.untyped]]) }
  def get_bookings
    check_connection.execute "SELECT * FROM Bookings"
  end

  sig { params(booking: T::Hash[Symbol, T.untyped]).returns(T::Array[T.untyped]) }
  def make_booking(booking)
    check_connection.execute "INSERT INTO Bookings (title, description, color, start_date, length, times, type) VALUES (?, ?, ?, ?, ?, ?, ?)",
      [booking[:title], booking[:description], booking[:color], booking[:start_date], booking[:length], booking[:times], booking[:type]]
  end

  sig { params(task: T::Hash[Symbol, T.untyped]).returns(T::Array[T.untyped]) }
  def make_task(task)
    check_connection.execute "INSERT INTO Tasks (title, description, color, due_date) VALUES (?, ?, ?, ?)",
      [task[:title], task[:description], task[:color], task[:due_date]]
  end

  private

  sig { returns(SQLite3::Database) }
  def check_connection
    raise StandardError, "No database found" unless @db
    @db
  end
end
