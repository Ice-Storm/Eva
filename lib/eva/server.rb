require 'libuv'
require 'uri'

require_relative './watch_parser'
require_relative './const'
require_relative './client'

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
#        协程
#         co(@reactor.work(proc {
#           tcp = Eva::Client.new(@reactor)
#           tcp.handle_request(@app)
#         }))
      end
    end
  end
end