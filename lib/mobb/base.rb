require 'repp'
require "mobb/version"

module Mobb
  class Matcher
    def initialize(pattern, options) @pattern, @options = pattern, options; end
    def regexp?; pattern.is_a?(Regexp); end
    def inspect; "pattern: #{@pattern}, options #{@options}"; end
    def invoke(time = Time.now) @options[:last_invoked] = time; end

    def match?(context)
      case context
      when String
        string_matcher(context)
      when Time
        # TODO: do something
        false
      when Array
        context.all? { |c| match?(c) }
      else
        false
      end
    end

    class Matched
      attr_reader :pattern, :matched
      def initialize(pattern, matched) @pattern, @matched = pattern, matched; end
    end

    def pattern; @pattern; end

    def string_matcher(string)
      case pattern
      when Regexp
        if res = pattern.match(string)
          Matched.new(pattern, res.captures)
        else
          false
        end
      when String
        @options[:laziness] ? string.include?(pattern) : string == pattern
      else
        false
      end
    end
  end

  class Base
    def call(env)
      dup.call!(env)
    end

    def tick(env)
      dup.tick!(env)
    end

    def call!(env)
      @env = env
      invoke { dispatch! }
      [@body, @attachments]
    end

    def tick!(env)
      fail # TODO: write logic here
    end

    def dispatch!
      # TODO: encode input messages

      invoke do
        # TODO: before filters
        handle_event
      end
    ensure
      # TODO: after fillters
    end

    def invoke
      res = catch(:halt) { yield }
      return if res.nil?
      
      res = [res] if String === res
      if Array === res && String === res.first
        tmp = res.dup
        @body = tmp.shift
        @attachments = tmp.pop
      else
        @attachments = res
      end
      nil
    end

    def handle_event(base = settings, passed_block = nil)
      if responds = base.events[@env.event_type]
        responds.each do |pattern, block, conditions|
          process_event(pattern, conditions) do |*args|
            event_eval { block[*args] }
          end
        end
      end

      # TODO: Define respond missing if receive reply message
      nil
    end

    def process_event(pattern, conditions, block = nil, values = [])
      res = pattern.match?(@env.body)
      catch(:pass) do
        conditions.each { |c| throw :pass unless c.bind(self).call }

        case res
        when ::Mobb::Matcher::Matched
          yield(self, *(res.matched))
        when TrueClass
          yield self
        else
          nil
        end
      end
    end

    def event_eval; throw :halt, yield; end

    def settings
      self.class.settings
    end

    class << self
      CALLERS_TO_IGNORE = [
        /\/mobb(\/(base|main|show_exceptions))?\.rb$/,   # all sinatra code
        /^\(.*\)$/,                                         # generated code
        /rubygems\/(custom|core_ext\/kernel)_require\.rb$/, # rubygems require hacks
        /active_support/,                                   # active_support require hacks
        /bundler(\/runtime)?\.rb/,                          # bundler require hacks
        /<internal:/,                                       # internal in ruby >= 1.9.2
        /src\/kernel\/bootstrap\/[A-Z]/                     # maglev kernel files
      ]

      attr_reader :events

      def reset!
        @events = {}
        @conditions = []
      end

      def settings
        self
      end

      def receive(pattern, options = {}, &block) event(:message, pattern, options, &block); end
      alias :on :receive

      #def every(pattern, options = {}, &block) event(:cron, pattern, options, &block); end

      def event(type, pattern, options, &block)
        (@events[type] ||= []) << compile!(type, pattern, options, &block)
      end

      def compile!(type, pattern, options, &block)
        options.each_pair { |option, args| send(option, *args) }

        matcher = compile(pattern, options)
        unbound_method = generate_method("#{type}", &block)
        conditions, @conditions = @conditions, []
        wrapper = block.arity != 0 ?
          proc { |instance, args| unbound_method.bind(instance).call(*args) } :
          proc { |instance, args| unbound_method.bind(instance).call }

        [ matcher, wrapper, conditions ]
      end

      def compile(pattern, options) Matcher.new(pattern, options); end

      def generate_method(name, &block)
        define_method(name, &block)
        method = instance_method(name)
        remove_method(name)
        method
      end

      def helpers(*extensions, &block)
        class_eval(&block)   if block_given?
        include(*extensions) if extensions.any?
      end

      def development?; environment == :development; end
      def production?; environment == :production; end
      def test?; environment == :test; end

      def set(option, value = (not_set = true), ignore_setter = false, &block)
        raise ArgumentError if block && !not_set
        value, not_set = block, false if block

        if not_set
          raise ArgumentError unless option.respond_to?(:each)
          option.each { |k,v| set(k,v) }
          return self
        end

        setter_name = "#{option}="
        if respond_to?(setter_name) && ! ignore_setter
          return __send__(setter_name, value)
        end

        setter = proc { |val| set(option, val, true) }
        getter = proc { value }

        case value
        when Proc
          getter = value
        when Symbol, Integer, FalseClass, TrueClass, NilClass
          getter = value.inspect
        when Hash
          setter = proc do |val|
            val = value.merge(val) if Hash === val
            set(option, val, true)
          end
        end

        define_singleton(setter_name, setter)
        define_singleton(option, getter)
        define_singleton("#{option}?", "!!#{option}") unless method_defined?("#{option}?")
        self
      end

      def condition(name = "#{caller.first[/`.*'/]} condition", &block)
        @conditions << generate_method(name, &block)
      end

      def enable(*options) options.each { |option| set(option, true) }; end
      def disable(*options) options.each { |option| set(option, false) }; end
      def clear(*options) options.each { |option| set(option, nil) }; end

      def run!(options = {}, &block)
        return if running?

        set options
        handler = detect_repp_handler
        handler_name = handler.name.gsub(/.*::/, '')
        service_settings = settings.respond_to?(:service_settings) ? settings.service_settings : {}
        
        begin
          start_service(handler, service_settings, handler_name, &block)
        rescue => e
          $stderr.puts e.message
          $stderr.puts e.backtrace
        ensure
          quit!
        end
      end

      def quit!
        return unless running?
        running_service.respond_to?(:stop!) ? running_service.stop! : running_service.stop
        $stderr.puts "== Great sound Mobb, thank you so much"
        clear :running_service, :handler_name
      end

      def running?
        running_service?
      end

      private

      def start_service(handler, service_settings, handler_name)
        handler.run(self, service_settings) do |service|
          $stderr.puts "== Mobb (v#{Mobb::VERSION}) is in da house with #{handler_name}. Make some noise!"

          setup_traps
          set running_service: service
          set handler_name: handler_name

          yield service if block_given?
        end
      end

      def setup_traps
        if traps?
          at_exit { quit! }

          [:INT, :TERM].each do |signal|
            old_handler = Signal.trap(signal) do
              quit!
              old_handler.respond_to?(:call) ?  old_handler.call : exit
            end
          end

          disable :traps
        end
      end

      def detect_repp_handler
        services = Array(service)
        services.each do |service_name|
          begin
            return Repp::Handler.get(service_name.to_s)
          rescue LoadError, NameError
          end
        end
        fail "Service handler (#{services.join(',')}) not found"
      end

      def define_singleton(name, content = Proc.new)
        singleton_class.class_eval do
          undef_method(name) if method_defined?(name)
          String === content ? class_eval("def #{name}() #{content}; end") : define_method(name, &content)
        end
      end

      def caller_files
        cleaned_caller(1).flatten
      end

      def cleaned_caller(keep = 3)
        caller(1).
          map!    { |line| line.split(/:(?=\d|in )/, 3)[0,keep] }.
          reject { |file, *_| CALLERS_TO_IGNORE.any? { |pattern| file =~ pattern } }
      end

      def inherited(subclass)
        subclass.reset!
        subclass.set :app_file, caller_files.first unless subclass.app_file?
        super
      end
    end

    reset!

    set :name, 'mobb'
    set :environment, (ENV['APP_ENV'] || ENV['REPP_ENV'] || :development).to_sym

    disable :run, :quiet
    clear :running_service, :handler_name
    enable :traps
    set :service, %w[shell]

    clear :app_file
  end

  class Application < Base
    set :logging, Proc.new { !test? }
    set :run, Proc.new { !test? }
    clear :app_file

    def self.register(*extensions, &block)
      added_methods = extensions.flat_map(&:public_instance_methods)
      Delegator.delegate(*added_methods)
      super(*extensions, &block)
    end
  end

  module Delegator #:nodoc:
    def self.delegate(*methods)
      methods.each do |method_name|
        define_method(method_name) do |*args, &block|
          return super(*args, &block) if respond_to? method_name
          Delegator.target.send(method_name, *args, &block)
        end
        private method_name
      end
    end

    delegate :receive, :on, #:every,
      :set, :enable, :disable, :clear,
      :helpers

    class << self
      attr_accessor :target
    end

    self.target = Application
  end
end
