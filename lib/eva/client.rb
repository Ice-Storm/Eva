require 'stringio'
require 'uri'
require 'rack'

require_relative './const'
require_relative './watch_parser'

module Eva
  class Client

    include Eva::Const

    class EvaRuntimeError < RuntimeError; end

    def initialize(reactor, state)
      @reactor = reactor
      @server = @reactor.tcp
      @state = state
      # @timeout = @reactor.timer do
      #   @reactor.stop
      #   @server.close
      #   p "test timed out"
      # end
      #@timeout.start(100)
      # @watch_parser = nil
    end

    def bind
      @server.close && @state == :run if @state == :restart
      @server.bind('127.0.0.1', 24567) do |client|
        client.progress { |buffer| yield(client, buffer) if block_given? }
        client.start_read
        client.catch { |args| p args }
      end
      set_listen(1024)
      @server.catch { |args| p args }
    end

    def set_listen(num)
      @server.listen(num)
    end

    def handle_request(app)
      bind do |client, buffer|
        @watch_parser = Eva::WatchParser.new(buffer)
        @watch_parser.execute nil do |env|
          handle_rack(client, app, env)
          # client.finally { @server.close }
        end
      end
    end

    def handle_rack(client, app, env)
      StringIO.class_eval do
        def append(*values)
          begin
            values.each { |v| write v }
          rescue IOError
            raise 'Response IOError'
          end
        end
      end

      normalize_env(env)

      # 检查 env 是否符合规范
      # Rack::Lint.new(app).call(env)

      res_io = StringIO.new

      begin
        status, headers, res_body = app.call(env)

        status = status.to_i

        if status == -1
          unless headers.empty? and res_body == []
            raise "async response must have empty headers and body"
          end

          return :async
        end

        content_length = nil

        if res_body.kind_of? Array and res_body.size == 1
          content_length = res_body[0].bytesize
        end

        http_11 = if env[HTTP_VERSION] == HTTP_11
          allow_chunked = true
          keep_alive = env.fetch(HTTP_CONNECTION, '').downcase != CLOSE
          include_keepalive_header = false
          res_io.append HTTP_11_200 if status == 200
          true
        else
          allow_chunked = false
          keep_alive = env.fetch(HTTP_CONNECTION, '').downcase == KEEP_ALIVE
          include_keepalive_header = keep_alive
          res_io.append HTTP_10_200 if status == 200
          false
        end

        no_body ||= status < 200 || STATUS_WITH_NO_ENTITY_BODY[status]

        headers.each { |k, vs| res_io.append(k, COLON, vs, LINE_END) }

        if include_keepalive_header
          res_io.append CONNECTION_KEEP_ALIVE
        elsif http_11 && !keep_alive
          res_io.append << CONNECTION_CLOSE
        end

        if no_body
          if content_length && status != 204
            res_io.append CONTENT_LENGTH_S, content_length.to_s, LINE_END
          end

          res_io.append LINE_END
          return keep_alive
        end

        if content_length
          res_io.append CONTENT_LENGTH_S, content_length.to_s, LINE_END
          chunked = false
        elsif !response_hijack and allow_chunked
          res_io.append TRANSFER_ENCODING_CHUNKED
          chunked = true
        end

        res_io.append LINE_END

        res_body.each do |part|
          if chunked
            next if part.bytesize.zero?
            res_io.append part.bytesize.to_s(16), LINE_END, part, LINE_END
          else
            res_io.append part
          end
          res_io.flush
        end

        if chunked
          res_io.append CLOSE_CHUNKED
          res_io.flush
        end

        begin
          client.write res_io.string
          client.close
        rescue  Errno::EPIPE, SystemCallError, IOError
          raise ConnectionError, 'Socket timeout writing data'
        ensure
          # uncork_socket client
          #
          # body.close
          # req.tempfile.unlink if req.tempfile
          # res_body.close if res_body.respond_to? :close
          env[RACK_AFTER_REPLY].each { |o| o.call }
        end
      rescue EvaRuntimeError => e
        $stderr.puts "Exception handling servers: #{e.message} (#{e.class})"
        $stderr.puts e.backtrace
      end
    end

    def normalize_env(env)

      env[RACK_URL_SCHEME] = env[HTTPS_KEY] ? HTTPS : HTTP

      # A rack extension. If the app writes #call'ables to this
      # array, we will invoke them when the request is done.
      #
      env[RACK_AFTER_REPLY] = []

      if host = env[HTTP_HOST]
        if colon = host.index(":")
          env[SERVER_NAME] = host[0, colon]
          env[SERVER_PORT] = host[colon+1, host.bytesize]
        else
          env[SERVER_NAME] = host
          env[SERVER_PORT] = 24567
        end
      else
        env[SERVER_NAME] = LOCALHOST
        env[SERVER_PORT] = 24567
      end

      unless env[REQUEST_PATH]
        uri = URI.parse(env[REQUEST_URI])
        env[REQUEST_PATH] = uri.path

        raise 'No REQUEST PATH' unless env[REQUEST_PATH]

        env[QUERY_STRING] = uri.query if uri.query
      end

      env[PATH_INFO] = env[REQUEST_PATH]

      unless env.key?(REMOTE_ADDR)
        begin
          addr = '127.0.0.1'      #client.peerip
        rescue Errno::ENOTCONN
          addr = LOCALHOST_IP
        end

        addr = LOCALHOST_IP if addr.empty?

        env[REMOTE_ADDR] = addr
      end
    end

    def default_server_port(env)
      return PORT_443 if env[HTTPS_KEY] == 'on' || env[HTTPS_KEY] == 'https'
      env['HTTP_X_FORWARDED_PROTO'] == 'https' ? PORT_443 : PORT_80
    end

    def try_to_finish

    end

  end
end