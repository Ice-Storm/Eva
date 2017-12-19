require 'fiber'
require 'http-parser'

module Eva
  class Parser

    def initialize
      @parser = HttpParser::Parser.new_instance
    end

    def execute(buffer)
      body = []
      header_field = []
      header_value = []
      parser_fiber = binding_parse_event(buffer)
      while parser_fiber.alive? do
        inst, state, data = parser_fiber.resume

        method       = inst.http_method if state == :begin
        url          = data             if state == :url
        body         << data            if state == :body
        header_field << data            if state == :header_field
        header_value << data            if state == :header_value
      end
      [method, url, header_field, header_value, body]
    end

    private

    def binding_parse_event(buffer)
      Fiber.new do
        request = HttpParser::Parser.new do |parser|
          parser.on_message_begin    { |inst|       Fiber.yield inst, :begin }
          parser.on_message_complete { |inst|       Fiber.yield inst, :complete }
          parser.on_url              { |inst, data| Fiber.yield inst, :url, data }
          parser.on_header_field     { |inst, data| Fiber.yield inst, :header_field, data }
          parser.on_header_value     { |inst, data| Fiber.yield inst, :header_value, data }
          parser.on_body             { |inst, data| Fiber.yield inst, :body, data }
        end
        request.parse @parser, buffer
      end
    end
  end
end