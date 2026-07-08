require_relative 'app/menu'
require_relative 'app/schedule_screen'

loop do
  case Menu.use_menu(0, 'Get ready to do', %w[Schedule])
  when 'Schedule'
    ScheduleScreen.show
  when 'Quit'
    exit
  end
end
