require 'eva/runner'

module Eva
  class Single < Runner

    def stop
      @server.stop
    end

    def run
      output_header 'single'
      @launcher.write_state

      begin
        @server.run
      rescue => e
        log 'unknown error occurred'
        log e.message
      end
    end

  end
end