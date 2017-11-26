require 'eva/httpparse'
require 'eva/const'

require 'stringio'

module Eva
  class WatchParser

    include Eva::Const

    class HttpParserError < RuntimeError; end

    def initialize(buffer)
      @http_parse = Eva::Parser.new

      @proto_env = {
          "rack.version".freeze => RACK_VERSION,
          #"rack.errors".freeze => events.stderr,
          "rack.errors".freeze => $stderr,
          "rack.multithread".freeze => false,
          "rack.multiprocess".freeze => false,
          "rack.run_once".freeze => true,
          "SCRIPT_NAME".freeze => "",
          "QUERY_STRING".freeze => "",
          SERVER_PROTOCOL => HTTP_11,
          SERVER_SOFTWARE => PUMA_SERVER_STRING,
          GATEWAY_INTERFACE => CGI_VER
      }

      @buffer = buffer
    end

    def execute(callback, &blk)
      callback ||= blk

      @http_method, @http_url, @http_header_field, @http_header_value, @http_body = @http_parse.execute(@buffer)

      raise HttpParserError, 'Header is longer than allowed, aborting client early.' if header_is_overflow?

      rack_env = adapter
      callback.call(rack_env)
    end

    def adapter
      env_hash = []

      @http_header_field.each_with_index do |field, index|
        if %w(CONTENT-TYPE CONTENT-LENGTH).include?(field.upcase)
          header_field = field.upcase.gsub('-', '_')
        else
          header_field = "HTTP_#{field.upcase.gsub('-', '_')}"
        end
        header_value = @http_header_value[index]
        env_hash << ([] << header_field << header_value)
      end

      env_hash << [RACK_INPUT, StringIO.new(@http_body.first || '')]
      env_hash << [REQUEST_METHOD, @http_method.to_s]
      env_hash << [REQUEST_URI, @http_url]

      @proto_env.merge(env_hash.to_h)
    end

    def header_is_overflow?
      h = @http_header_field + @http_header_value
      h.first.bytesize >= MAX_HEADER unless h.empty?
    end

  end
end