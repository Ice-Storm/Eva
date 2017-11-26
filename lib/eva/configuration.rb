require 'eva/dsl'

module Eva
  module ConfigDefault
    DefaultRackup = 'config.ru'
    DefaultTCPHost = '0.0.0.0'
    DefaultTCPPort = 7777
    DefaultWorkerTimeout = 60
    DefaultWorkerShutdownTimeout = 30
  end

  class UserFileDefaultOptions
    def initialize(user_options, default_options)
      @user_options    = user_options
      @file_options    = {}
      @default_options = default_options
    end

    attr_reader :user_options, :file_options, :default_options

    def [](key)
      return user_options[key]    if user_options.key?(key)
      return file_options[key]    if file_options.key?(key)
      return default_options[key] if default_options.key?(key)
    end

    def []=(key, value)
      user_options[key] = value
    end

    def fetch(key, default_value = nil)
      self[key] || default_value
    end

    def all_of(key)
      user    = user_options[key]
      file    = file_options[key]
      default = default_options[key]

      user    = [user]    unless user.is_a?(Array)
      file    = [file]    unless file.is_a?(Array)
      default = [default] unless default.is_a?(Array)

      user.compact!
      file.compact!
      default.compact!

      user + file + default
    end

    def finalize_values
      @default_options.each do |k,v|
        if v.respond_to? :call
          @default_options[k] = v.call
        end
      end
    end
  end

  class Configuration

    include ConfigDefault

    def initialize(user_options={}, default_options = {}, &block)
      default_options = self.eva_default_options.merge(default_options)

      @options     = UserFileDefaultOptions.new(user_options, default_options)
      p @options
      # @plugins     = PluginLoader.new
      @user_dsl    = DSL.new(@options.user_options, self)
      @file_dsl    = DSL.new(@options.file_options, self)
      @default_dsl = DSL.new(@options.default_options, self)

      configure(&block) if block
    end

    attr_reader :options #, :plugins

    def configure
      yield @user_dsl, @file_dsl, @default_dsl
    end

    # Injects the Configuration object into the env
    class ConfigMiddleware
      def initialize(config, app)
        @config = config
        @app = app
      end

      def call(env)
        env[Const::PUMA_CONFIG] = @config
        @app.call(env)
      end
    end

    def rackup
      @options[:rackup]
    end

    def load_rackup
      raise "Missing rackup file '#{rackup}'" unless File.exist?(rackup)

      rack_app, rack_options = ::Rack::Builder.parse_file(rackup)
      @options.file_options.merge!(rack_options)

      config_ru_binds = []
      rack_options.each do |k, v|
        config_ru_binds << v if k.to_s.start_with?("bind")
      end

      @options.file_options[:binds] = config_ru_binds unless config_ru_binds.empty?

      rack_app
    end

    def app
      found = options[:app] || load_rackup

      if @options[:mode] == :tcp
        #require 'puma/tcp_logger'

        logger = @options[:logger]
        quiet = !@options[:log_requests]
        return TCPLogger.new(logger, found, quiet)
      end

      if @options[:log_requests]
        require './commonlogger'
        logger = @options[:logger]
        found = CommonLogger.new(found, logger)
      end

      ConfigMiddleware.new(self, found)
    end

    def eva_default_options
      {
          #:log_requests => false,
          :log_requests => true,
          :pidfile => './pid',
          #:debug => false,
          :binds => ["tcp://#{DefaultTCPHost}:#{DefaultTCPPort}"],
          #:workers => 0,
          #:daemon => false,
          :mode => :http,
          :worker_timeout => DefaultWorkerTimeout,
          :worker_boot_timeout => DefaultWorkerTimeout,
          :worker_shutdown_timeout => DefaultWorkerShutdownTimeout,
          :remote_address => :socket,
          #:tag => method(:infer_tag),
          :environment => ->{ ENV['RACK_ENV'] || "development" },
          :rackup => DefaultRackup,
          :logger => STDOUT,
          :persistent_timeout => Const::PERSISTENT_TIMEOUT,
          :first_data_timeout => Const::FIRST_DATA_TIMEOUT
      }
    end


    def load
      files = @options.all_of(:config_files)

      if files.empty?
        files << %W(config/eva/#{@options[:environment]}.rb config/eva.rb).find { |f| File.exist?(f) }
      elsif files == ['-']
        files = []
      end

      files.each do |f|
        @file_dsl._load_from(f)
      end
      @options
    end

  end
end