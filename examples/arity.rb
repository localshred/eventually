$LOAD_PATH << File.expand_path('../lib', File.dirname(__FILE__))
require 'eventually'

class Car
  include Eventually
  emits(:driving, :arity => 1)
  emits(:stopped, :arity => 0)
  emits(:reversing, :arity => -1)
  emits(:turning, :arity => 3)
end

car = Car.new
car.on(:driving) do |mph|
  puts 'The car is traveling %d mph' % mph
end

# Notice the odd empty "pipes" below...
# Checking arity on a block will give -1 for no args.
# If you're expecting arity == 0 you have to pass empty pipes (e.g. do ||)
# In other words, it doesn't make a ton of sense to
# expect an arity of zero, better a -1 validation such
# as on the :reversing event
car.on(:stopped) do ||
  puts 'The car stopped'
end

# Validated on -1 (no arguments)
car.on(:reversing) do
  puts 'The car is reversing'
end

begin
  car.on(:turning) do |direction|
    puts 'Car is turning %s' % direction
  end
rescue => e
  # "Invalid callback arity for event :turning (expected 3, received 1)"
  puts e.message
end