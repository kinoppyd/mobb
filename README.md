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

You can use conditions `ignore_bot` and `reply_to_me`.

```ruby
require 'mobb'
set :service, 'slack'

# You must set `ignore_bot` true when response same message
on 'Yo', ignore_bot: true do
  'Yo'
end

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
