require 'rack/handler'
<<<<<<< HEAD

require_relative '../../../lib/eva/server'
=======
require 'eva/launcher'
require 'eva/configuration'
require 'eva/events'
>>>>>>> dev

module Rack
  module Handler
    module Eva

<<<<<<< HEAD
      def self.run(app, options = {})
        ::Eva::Server.new(app).run
=======
      def self.config(app, options={})
        conf = ::Eva::Configuration.new(options, {}) do |user_config, file_config, default_config|
          user_config.app(app)
        end
        conf
      end

      def self.run(app, options = {})
        conf = self.config(app, options)
        events = ::Eva::Events.stdio
        launcher = ::Eva::Launcher.new(conf, :events => events)

        launcher.run
        #::Eva::Server.new(app).run
>>>>>>> dev
      end

    end
    register :eva, Eva
  end
end
