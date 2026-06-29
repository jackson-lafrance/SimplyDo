require_relative 'app/menu'
require_relative 'app/schedule'
require_relative 'app/todo'
require_relative 'app/habits'

loop do
  case Menu.use_menu(0, 'Get ready to do', %w[Schedule Todo Habits])
  when 'Schedule'
    Schedule
  when 'Todo'
    Todo
  when 'Habits'
    Habits
  when 'Quit'
    exit
  end
end
