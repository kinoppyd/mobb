require 'mobb'

set :service, 'slack'
set :name, "example bot"

on "hello" do
  "Hi! I'm #{settings.name}"
end

# Warning this is bad implementation
# inifinity loop happend
receive "Yo", laziness: true do
  "Yo"
end

receive /hey (\w+)/ do |someone|
  "hey #{someone}, waz up?"
end

# This function is not implements yet
#every 1.day, at: '15:30', exclude: :holiday do
#  'Stund up daily meeting time!'
#end
