$LOAD_PATH << File.expand_path('../lib', File.dirname(__FILE__))
require 'eventually'

class Door
  include Eventually
  enable_strict!
  emits :opened, :closed
end

door = Door.new
door.on(:opened) do
  puts 'door was opened'
end

door.on(:closed) do
  puts 'door was closed'
end

begin
  # This will raise an error!
  door.on(:slammed) do
    puts 'oh noes'
  end
rescue => e
  # "Event type :slammed will not be emitted. Use Door.emits(:slammed)"
  puts e.message
end