require 'libuv'
require 'uri'

require 'eva/watch_parser'
require 'eva/const'
require 'eva/client'

module Eva
  class Server

    include Eva::Const

    def initialize(app)
      @reactor = Libuv::Reactor.new
      @app = app
      @state = :stop
    end

    attr_accessor :reactor, :state

    def run
      @reactor.run do |reactor|
        tcp = Eva::Client.new(reactor, @state)
        tcp.handle_request(@app)
      end
    end
  end
end