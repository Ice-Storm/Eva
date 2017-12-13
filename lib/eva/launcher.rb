require 'eva/single'
require 'eva/cluster'
require 'eva/state_file'
require 'eva/const'

module Eva

  class Launcher
    def initialize(conf, launcher_args={})
      @conf     = conf
      @options  = @conf.options
      @events   = launcher_args[:events] || Events::DEFAULT
      @server   = Eva::Single.new(self, @conf)
      @deferred = @server.reactor.defer
      @promise  = @deferred.promise
    end

    attr_accessor :events

    def run
      setup_signals
      @server.run
    end

    def write_state
      write_pid
    end

    # Delete the configured pidfile
    def delete_pidfile
      path = @options[:pidfile]
      File.unlink(path) if path && File.exist?(path)
    end

    # If configured, write the pid of the current process out
    # to a file.
    def write_pid
      path = @options[:pidfile]
      return unless path

      File.open(path, 'w') { |f| f.puts Process.pid }
      cur = Process.pid
      at_exit do
        delete_pidfile if cur == Process.pid
      end
    end

    def log(str)
      @server.log str
    end

    def graceful_stop
      @server.stop
      log "=== eva shutdown: #{Time.now} ==="
      log "- Goodbye!"
    end

    def setup_signals

      # 11 -> phased-restart
      # 13 -> restart
      # s = { :SIG_USR1 => 11, :SIG_USR2 => 13 }

      @server.reactor.on_program_interrupt do
        p 'on_program_interrupt'
        
       # @server.restart
      end

      # evactl stop
      @server.reactor.signal(:TERM) do
        graceful_stop
      end

      @server.reactor.signal(:SIGINT) do
        p 'reactor SIGINT'
        graceful_stop
      end

      @server.reactor.signal(:SIGHUP) do
        p 'reactor SIGHUP'
      end

      @server.reactor.signal(11) do
        p 'reactor SIGUSR1'
      end

      # evactl restart
      # rebinding tcp
      @server.reactor.signal(13) do
        reactor_stop = Proc.new { @server.reactor.tcp.close }
        @server.reactor.run do
          @promise.then reactor_stop, nil do 
            @server.run
          end
          @deferred.resolve
        end
      end
    
    end
  end
end
