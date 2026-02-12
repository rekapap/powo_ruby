# frozen_string_literal: true

require "json"

require_relative "../errors"

module PowoRuby
  module RequestSupport
    # Translates an HTTP response into either parsed JSON or a rich error.
    #
    # POWO typically returns JSON bodies; this handler:
    # - raises typed errors for 4xx/5xx/429
    # - parses JSON for successful responses
    class ResponseHandler
      # Handle an HTTP response.
      #
      # @param response [#status,#body,#headers]
      # @param method [Symbol, String]
      # @param url [String]
      # @return [Hash, Array]
      def handle(response, method:, url:)
        status = response.status.to_i
        body = response.body
        headers = response.headers

        if status == 429
          raise RateLimitedError.new(
            "Rate limited by POWO (HTTP 429)",
            status: status,
            method: method,
            url: url,
            body: body,
            headers: headers
          )
        end

        if status >= 500
          raise ServerError.new(
            "POWO server error (HTTP #{status})",
            status: status,
            method: method,
            url: url,
            body: body,
            headers: headers
          )
        end

        if status >= 400
          raise ClientError.new(
            "POWO request failed (HTTP #{status})",
            status: status,
            method: method,
            url: url,
            body: body,
            headers: headers
          )
        end

        parse_json(body, method: method, url: url)
      end

      private

      # Parse a JSON response body.
      #
      # @param body [String, Hash, Array, Object]
      # @param method [Symbol, String]
      # @param url [String]
      # @return [Hash, Array, Object]
      def parse_json(body, method:, url:)
        return body if body.is_a?(Hash) || body.is_a?(Array)

        text = body.to_s
        return {} if text.strip.empty?

        JSON.parse(text)
      rescue JSON::ParserError => e
        raise ParseError.new("Failed to parse JSON response: #{e.message}", method: method, url: url, body: body)
      end
    end
  end
end
