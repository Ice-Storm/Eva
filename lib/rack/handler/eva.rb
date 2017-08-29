require 'rack/handler'

require_relative '../../../lib/eva/server'

module Rack
  module Handler
    module Eva

      def self.run(app, options = {})
        ::Eva::Server.new(app).run
      end

    end
    register :eva, Eva
  end
end
