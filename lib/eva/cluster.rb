require 'libuv'
require 'eva/runner'
require 'eva/server'

module Eva
  class Cluster < Runner

    WORKER_CHECK_INTERVAL = 5

    def initialize(cli)
      # super cli

      @workers = []
      @cpus = Libuv.cpu_count
    end

    class Worker
      def initialize(idx, pid, phase, options, server)
        @index = idx
        @pid = pid
        @phase = phase
        @stage = :started
        @signal = "TERM"
        @options = options
        @first_term_sent = nil
        @last_checkin = Time.now
        @last_status = '{}'
        @dead = false
        @server = server

        work_info
      end

      attr_reader :index, :pid, :phase, :signal, :last_checkin, :last_status, :server

      def work_info
        p "eva: cluster worker #{@index}: #{@pid}"
      end

      def ping_timeout?(which)
        Time.now - @last_checkin > which
      end
    end

    def fork_workers
      master = Process.pid

      @cpus.times do
        idx = next_worker_index
        server = start_server

        pid = fork { server }
        if !pid
          log "! Complete inability to spawn new workers detected"
          log "! Seppuku is the only choice."
          exit! 1
        end

        @workers << Worker.new(idx, master, 1, 1, server)
      end
    end

    def check_workers(force=false)
      return if !force && @next_check && @next_check >= Time.now

      @next_check = Time.now + WORKER_CHECK_INTERVAL

      @workers.each do |worker|

      end

    end

    def next_worker_index
      all_positions = 0...@cpus
      occupied_positions = @workers.map { |w| w.index }
      available_positions = all_positions.to_a - occupied_positions
      available_positions.first
    end

    def run
      fork_workers
      @workers.each { |work| work.server.run }
    end

  end
end