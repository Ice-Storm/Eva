require 'eva/const'
require 'eva/server'
require 'eva/events'

module Eva
  class Runner

    include Eva::Const

    def initialize(cli, conf)
      @launcher = cli
      @events = cli.events
      @conf = conf
      @server = Eva::Server.new(@conf.app)
    end

    def runnning?
      @server.reactor.running?
    end

    def reactor
      @server.reactor
    end

    def log(str)
      @events.log str
    end

    def ruby_engine
      if !defined?(RUBY_ENGINE) || RUBY_ENGINE == "ruby"
        "ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}"
      else
        if defined?(RUBY_ENGINE_VERSION)
          "#{RUBY_ENGINE} #{RUBY_ENGINE_VERSION} - ruby #{RUBY_VERSION}"
        else
          "#{RUBY_ENGINE} #{RUBY_VERSION}"
        end
      end
    end

    def output_header(mode)
      log "Eva starting in #{mode} mode..."
      log "* Version #{Eva::Const::EVA_VERSION} (#{ruby_engine}), codename: #{Eva::Const::CODE_NAME}"
      log "* Environment: #{ENV['RACK_ENV']}"

      # if @options[:mode] == :tcp
      #   log "* Mode: Lopez Express (tcp)"
      # end
    end

  end
end
