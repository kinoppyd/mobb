# Mobb

Mobb is the simplest, most lightweight, fastest Bot framework written by Ruby.

# Install

you can install Mobb by rubygems like

```
gem isntall mobb
```

or you can use a bundler. Writes the following in Gemfile

```
source "https://rubygems.org"

gem "mobb", "~> 0.1"
```

and install

```
bundle install
```

# Examples

Write your logic in `app.rb` like...

```ruby
require 'mobb'

set :name, "example bot"

on "hello" do
  "hi! i'm #{settings.name}!"
end
```

and start mobb application

```
ruby app.rb
```

then the shell will start to wait for your input, so you can type 'hello' and hit enter, then you get.

```
hi! i'm example bot!"
```

## Helpers

You can define helper methods like this.

```ruby
require 'mobb'

helpers do
  def greet(name)
    "Hi #{name}, what't up"
  end
end

on "hello" do
  greet(@env.user.name)
end

```

## Conditions

You can use conditions `react_to_bot`, `include_myself` and `reply_to_me`.

```ruby
require 'mobb'
set :service, 'slack'

# Mobb ignore all bot messages, but when set reply_to_bot true, Mobb react all bot messages
# this example will act infinit loop when receive message 'Yo'
on 'Yo', react_to_bot: true do
  'Yo'
end

# This block react only message reply to bot
on /Hi/, reply_to_me: true do
  "Hi #{@env.user.name}"
end
```

And you can define conditions yourself.

```ruby
require 'mobb'
set :service, 'slack'

set(:probability) { |value| condition { rand <= value } }

on /Yo/, reply_to_me: true, probability: 0.1 do
  "Yo"
end

on /Yo/, reply_to_me: true do
  "Ha?"
end
```

# Chain methods

If you want to act heavy task your bot, you can use chain/trigger syntax.

```ruby
require 'mobb'

on /task start (\w+)/ do |name|
  chain 'heavy task1', 'heavy task2', name: name
  'start!'
end

trigger 'heavy task1' do
  payload = @env.payload
  sleep 19
  "task1 #{payload[:name]} done!"
end

trigger 'heavy task2' do
  payload = @env.payload
  sleep 30
  "task2 #{payload[:name]} done!"
end
```

# Pass

You can pass block to use pass keyword

```ruby
require 'mobb'

on 'yo' do
  $stderr.puts 'this block will be pass'
  pass
  'this value never evaluted'
end

on 'yo' do
  $stderr.puts 'catch!'
  'yo'
end
```

# Service handlers

Mobb is implemented based on [Repp](https://github.com/kinoppyd/repp) Interface.
Shell and Slack adapter is currently available.

```ruby
require 'mobb'
set :serice, 'slack'

on /hey (\w+)/ do |someone|
  "hey #{someone}, waz up?"
end
```

# TODO

+ Test, Test, Test
+ Documents
+ Parallel event handling
