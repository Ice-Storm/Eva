require 'optparse'
require 'uri'
require 'socket'

require_relative './server'
require_relative './client'
require_relative './launcher'
require_relative './configuration'

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


      @command = argv.shift

      # unless @config_file == '-'
      #   if @config_file.nil? and File.exist?('config/eva.rb')
      #     @config_file = 'config/eva.rb'
      #   end
      #
      #   if @config_file
      #     config = Puma::Configuration.new({ config_files: [@config_file] }, {})
      #     config.load
      #     @state              ||= config.options[:state]
      #     @control_url        ||= config.options[:control_url]
      #     @control_auth_token ||= config.options[:control_auth_token]
      #     @pidfile            ||= config.options[:pidfile]
      #   end
      # end


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
      @pid = File.open('./pid').gets.to_i
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
      #start if @command == "start"

      prepare_configuration

      send_signal

    rescue => e
      message e.message
      message e.backtrace
      exit 1
    end

  end
end