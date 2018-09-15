require 'mobb'

set :service, 'slack'
set :name, "example bot"

on "hello" do
  "Hi! I'm #{settings.name}"
end

# Warning this is bad implementation
# inifinity loop happend
# TODO: now broken
#receive "Yo", laziness: true do
#  "Yo"
#end

receive /hey (\w+)/ do |someone|
  "hey #{someone}, waz up?"
end

# Need dest_to condition to cron/every task
every :day, at: '12:30', dest_to: 'times_kinoppyd' do
  'Stund up daily meeting time!'
end
