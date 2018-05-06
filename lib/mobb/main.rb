require 'mobb/base'

module Mobb
  class Application < Base
    set app_file: caller_files.first || $0

    set :run, Proc.new { File.expand_path($0) == File.expand_path(app_file) }
  end

  at_exit { Application.run! if $!.nil? && Application.run? }
end

extend Mobb::Delegator

#class Repp::Builder
#  include Mobb::Delegator
#end
