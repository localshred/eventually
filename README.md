# Eventually

`Eventually` is a module that facilitates evented callback management *similar* to the [EventEmitter API](http://nodejs.org/docs/v0.4.7/api/events.html) in NodeJS. Support for Ruby's various lambda-ish callback styles is heavily baked in, so using blocks, lambdas, procs, or event detached methods works out of the box, batteries included. Simply include `Eventually` in the class you will be emitting events from, register some listeners and fire away.

```ruby
class Car
  include Eventually
  def stop
    #...
    emit(:stopped, 0)
  end
end

car = Car.new
car.on(:stopped) do |mph|
  puts 'the car stopped, sitting at %d mph' % mph
end
car.stop # this will indirectly invoke the above callback
```

## Pre-define Events

For documentation purposes, it can often be nice to define up front what events you'll be expecting to emit from the instances of a certain class. Anyone who's ever spent a couple of minutes trying to dig up their database columns from an ActiveRecord model knows what I'm talking about. Annoying. So `Eventually` let's you put that all up front in a nice DSL.

```ruby
class Car
  include Eventually
	emits :stopped, :started, :turning
	emits :reversing
end
```

The previous snippet acts mostly as documentation.

*See the **examples/basic.rb** file for a slightly more complicated setup than this one.*

## Callback arity validation

However, sometimes you want to be sure that a given registered callback will conform to your event interface, so specify an **arity validation**. Let's add another event to our definition and ensure that callbacks registering for that event must have an arity of 1.

```ruby
class Car
  include Eventually
	emits :driving, :arity => 1
end
car = Car.new
car.on(:driving) do
  puts 'The car is driving'
end
# Error will be raise explaining the arity mismatch (expected 1, received -1)
```

*See the **examples/arity.rb** file for more on this.*

## Strict Mode

Strict mode is useful if you want to enforce the `#emits` documentation as being the **ONLY** events that your instances can emit or be registered against.

```ruby
class Car
  include Eventually
  
  enable_strict!
  emits :started, :stopped
  
  def turn
    # Emitting :turning event here will throw an error in strict mode
    emit(:turning)
  end
end

car = Car.new
# Registering for the :turning event here will throw an error in strict mode
car.on(:turning) do
  puts 'the car is turning'
end

*See the **examples/scrict.rb** file for more on this.*

## More?

Further examples can be found in the examples directory. I know, novel idea that one.

## Contact

[@localshred](http://twitter.com/localshred) wrote this. He [sometimes blogs](http://www.rand9.com) too.
