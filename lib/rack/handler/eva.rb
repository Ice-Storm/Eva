require 'rack/handler'
require 'eva/launcher'
require 'eva/configuration'
require 'eva/events'

module Rack
  module Handler
    module Eva

      def self.config(app, options={})
        conf = ::Eva::Configuration.new(options, {}) do |user_config, file_config, default_config|
          user_config.app(app)
        end
        conf
      end

      def self.run(app, options = {})
        conf = self.config(app, options)
        events = ::Eva::Events.strings
        launcher = ::Eva::Launcher.new(conf, :events => events)

        launcher.run
        #::Eva::Server.new(app).run
      end

    end
    register :eva, Eva
  end
end
