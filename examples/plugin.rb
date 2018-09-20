require 'mobb'

module ExampleHelpers
  def greet(name)
    "Hi #{name}, I'm #{settings.name}"
  end
end

module ExampleExtensions
  def to_yo(flag)
    dest_condition(:to_yo) do |res|
      res.last[:dest_channel] = 'bot_test'
    end
  end
end

class Application < Mobb::Base
  helpers ExampleHelpers
  register ExampleExtensions

  set :name, 'deep'
  set :service, 'slack'

  on /Yo (.+)/ do |name|
    greet(name)
  end

  every :minute, to_yo: true do
    'Yo'
  end
end

Application.run!
