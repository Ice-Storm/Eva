require 'eva/runner'

module Eva
  class Single < Runner

    def stop
      set_state :stop
      start_server.reactor.stop
    end

    def runnning?
      start_server.reactor.running?
    end

    def run(state = :run)
      set_state state

      output_header 'single'
      @launcher.write_state

      begin
        start_server.run
      rescue => e
        log 'unknown error occurred'
        log e.message
        log e.trace
      end
    end

  end
end