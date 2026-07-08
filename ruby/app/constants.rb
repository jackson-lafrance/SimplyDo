module Constants
  module Terminal
    RESET = "\e[0m"

    GREEN = "\e[1;32m"
    RED = "\e[1;31m"
    YELLOW = "\e[1;33m"
    CYAN = "\e[1;36m"
    BLUE = "\e[1;34m"
    MAGENTA = "\e[1;35m"
    DIM = "\e[2m"

    TITLE = CYAN
    SUBTITLE = BLUE
    SELECTED = GREEN
    USER_INPUT = YELLOW
    ERROR = RED
    SUCCESS = GREEN
    WARNING = YELLOW
    KEY_HINT = YELLOW
    TOOLTIP_TEXT = DIM
    SEPARATOR = DIM
    BORDER = BLUE
    TODAY = CYAN
    EVENT_TIME = YELLOW
    EVENT_DURATION = CYAN
    RECURRING = MAGENTA
    PRIMARY_ACTION = CYAN
    EMPTY_STATE = DIM
  end

  module Schedule
    RECURRING_UNITS = %i[days weeks].freeze
  end
end
