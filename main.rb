# frozen_string_literal: true

require_relative "lib/blitz"
require_relative "lib/database"
require_relative "lib/display"

Blitz.check_reset
Blitz.blit(0, 0, "Hello")
Blitz.create_screen
gets&.chomp
