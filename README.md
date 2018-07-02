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
