require 'libuv'
require 'uri'

require 'eva/watch_parser'
require 'eva/const'
require 'eva/client'

module Eva
  class Server

    include Eva::Const

    def initialize(app)
      @app = app      
      @reactor = Libuv::Reactor.new
    end

    attr_accessor :reactor

    def stop
      @reactor.stop
    end

    def run
      @reactor.run do |reactor|
        tcp = Eva::Client.new(reactor)
        tcp.handle_request(@app)
      end
    end
  end
end