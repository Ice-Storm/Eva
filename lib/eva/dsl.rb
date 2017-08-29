module Eva
  class DSL
    def initialize(options, config)
      @config  = config
      @options = options
      @plugins = []
    end

    def inject(&blk)
      instance_eval(&blk)
    end

    def get(key, default = nil)
      @options[key.to_sym] || default
    end

    def plugin(name)
      @plugins << @config.load_plugin(name)
    end

    def app(obj=nil, &block)
      obj ||= block

      raise "Provide either a #call'able or a block" unless obj

      @options[:app] = obj
    end

    # Set the environment in which the Rack's app will run.
    def environment(environment)
      @options[:environment] = environment
    end

    # Load +path+ as a rackup file.

    def rackup(path)
      @options[:rackup] = path.to_s
    end

  end
end