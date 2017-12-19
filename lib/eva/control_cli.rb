require 'optparse'
require 'uri'
require 'socket'

require 'eva/cli'
require 'eva/server'
require 'eva/client'
require 'eva/launcher'
require 'eva/configuration'

module Eva
  class ControlCLI
    COMMANDS = %w{halt restart phased-restart start stats status stop reload-worker-directory}

    def initialize(argv, stdout=STDOUT, stderr=STDERR)
      @state = nil
      @quiet = false
      @pidfile = nil
      @pid = nil
      @control_url = nil
      @control_auth_token = nil
      @config_file = nil
      @command = nil

      @argv = argv.dup
      @stdout = stdout
      @stderr = stderr
      @cli_options = {}

      opts = OptionParser.new do |o|
        o.banner = "Usage: evactl (-p PID | -P pidfile | -S status_file | -C url -T token | -F config.rb) (#{COMMANDS.join("|")})"

        o.on "-S", "--state PATH", "Where the state file to use is" do |arg|
          @state = arg
        end

        o.on "-Q", "--quiet", "Not display messages" do
          @quiet = true
        end

        o.on "-P", "--pidfile PATH", "Pid file" do |arg|
          @pidfile = arg
        end

        o.on "-p", "--pid PID", "Pid" do |arg|
          @pid = arg.to_i
        end

        o.on "-C", "--control-url URL", "The bind url to use for the control server" do |arg|
          @control_url = arg
        end

        o.on "-T", "--control-token TOKEN", "The token to use as authentication for the control server" do |arg|
          @control_auth_token = arg
        end

        o.on "-F", "--config-file PATH", "Eva config script" do |arg|
          @config_file = arg
        end

        o.on_tail("-H", "--help", "Show this message") do
          @stdout.puts o
          exit
        end

        o.on_tail("-V", "--version", "Show version") do
          puts Const::EVA_VERSION
          exit
        end
      end

      opts.order!(argv) { |a| opts.terminate a }

      @command = argv.shift

      unless @config_file == '-'
        if @config_file.nil? and File.exist?('config/eva.rb')
          @config_file = 'config/eva.rb'
        end

        if @config_file
          config = Eva::Configuration.new({ config_files: [@config_file] }, {})
          config.load
          @state              ||= config.options[:state]
          @control_url        ||= config.options[:control_url]
          @control_auth_token ||= config.options[:control_auth_token]
          @pidfile            ||= config.options[:pidfile]
        end
      end

      # check present of command
      unless @command
        raise "Available commands: #{COMMANDS.join(", ")}"
      end

      unless COMMANDS.include? @command
        raise "Invalid command: #{@command}"
      end
    end

    def message(msg)
      @stdout.puts msg unless @quiet
    end

    def prepare_configuration
      @pid = File.open('/tmp/pid').gets.to_i
      # if @state
      #   unless File.exist? @state
      #     raise "State file not found: #{@state}"
      #   end
      #
      #   sf = Eva::StateFile.new
      #   sf.load @state
      #
      #   @control_url = sf.control_url
      #   @control_auth_token = sf.control_auth_token
      #   @pid = sf.pid
      # elsif @pidfile
      #   # get pid from pid_file
      #   @pid = File.open(@pidfile).gets.to_i
      # end
    end

    def send_signal
      unless @pid
        raise "Neither pid nor control url available"
      end

      begin

        case @command
          when "restart"
            Process.kill 13, @pid

          when "halt"
            Process.kill "QUIT", @pid

          when "stop"
            Process.kill "SIGTERM", @pid

          when "stats"
            puts "Stats not available via pid only"
            return

          when "reload-worker-directory"
            puts "reload-worker-directory not available via pid only"
            return

          when "phased-restart"
            Process.kill 11, @pid

          else
            message "Puma is started"
            return
        end

      rescue SystemCallError
        if @command == "restart"
          start
        else
          raise "No pid '#{@pid}' found"
        end
      end

      message "Command #{@command} sent success"
    end

    def run
      prepare_configuration
      send_signal
    rescue => e
      message e.message
      message e.backtrace
      exit 1
    end

    private

    def start
      cli = Eva::CLI.new(@argv)
      cli.run
    end

  end
end