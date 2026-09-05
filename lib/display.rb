# typed: true
# frozen_string_literal: true

require "io/console"
require "sorbet-runtime"

require_relative "blitz"

module Display
  extend T::Sig
  extend self

  def draw_display
    width = Blitz.width
    height = Blitz.height
    draw_frames(width, height)
  end

  sig { params(width: Integer, height: Integer).void }
  def draw_frames(width, height)
    horizontal = [Array.new(width, @horizontal_line)]
    vertical = Array.new(height) { [@vertical_line] }

    # chatbox and splitter
    Blitz.blit(0, width / 2 - 2, Array.new(height - @chat_height) { [@vertical_line] })
    Blitz.blit(height - @chat_height - 1, 0, horizontal)

    # left and right
    Blitz.blit(0, 0, vertical)
    Blitz.blit(0, width - 1, vertical)

    # bottom and top
    Blitz.blit(0, 0, horizontal)
    Blitz.blit(height - 1, 0, horizontal)

    # top corners
    Blitz.blit(0, 0, [["┏"]])
    Blitz.blit(0, width - 1, [["┓"]])

    # bottom corners
    Blitz.blit(height - 1, 0, [["┗"]])
    Blitz.blit(height - 1, width - 1, [["┛"]])

    # middle connectors
    Blitz.blit(0, width / 2 - 2, [["┳"]])
    Blitz.blit(height - @chat_height - 1, width / 2 - 2, [["┻"]])

    # side connectors
    Blitz.blit(height - @chat_height - 1, width - 1, [["┫"]])
    Blitz.blit(height - @chat_height - 1, 0, [["┣"]])

  end

  private

  @chat_height = 6
  @horizontal_line = "━"
  @vertical_line = "┃"
end
