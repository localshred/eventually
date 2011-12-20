$LOAD_PATH << File.expand_path('../lib', File.dirname(__FILE__))
require 'eventually'

SPEED_LIMIT = 65

class SpeedingCar
  include Eventually
  
  # Document the events we'll likely emit
  emits :stopped, :driving
  
  def stop
    puts 'Car is stopped'
    emit(:stopped)
  end
  
  def go(mph)
    puts 'Car is driving %d mph' % mph
    emit(:driving, mph)
  end
end

class PoliceCar
  def initialize(speeding_car)
    speeding_car.on(:stopped, method(:eat_donut))
    speeding_car.on(:driving, method(:arrest_if_speeding))
  end
  
  def eat_donut
    puts 'CHOMP'
  end
  
  def arrest_if_speeding(speed)
    if speed > SPEED_LIMIT
      puts 'ARREST THEM!'
    else
      eat_donut
    end
  end
end

car = SpeedingCar.new
police = PoliceCar.new(car)
car.stop
car.go(100)

# The above will write to stdout:
#
#  Car is stopped
#  CHOMP
#  Car is driving 100 mph
#  ARREST THEM!
#