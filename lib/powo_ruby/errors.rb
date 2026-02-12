# frozen_string_literal: true

module PowoRuby
  # Base error class for this gem.
  class Error < StandardError; end

  # Raised when configuration is invalid or incomplete.
  class ConfigurationError < Error; end

  # Raised when user input fails validation (e.g. missing query, wrong type).
  class ValidationError < Error; end

  # Raised when an HTTP request fails or cannot be processed.
  #
  # Most request errors include contextual fields like HTTP status, URL and response body.
  class RequestError < Error
    attr_reader :status, :method, :url, :body, :headers

    # @param message [String]
    # @param status [Integer, nil] HTTP status code
    # @param method [Symbol, String, nil] HTTP method (e.g. `:get`)
    # @param url [String, nil] full URL requested
    # @param body [Object, nil] response body (may be a String or parsed JSON)
    # @param headers [Hash, nil] response headers
    def initialize(message, status: nil, method: nil, url: nil, body: nil, headers: nil)
      super(message)
      @status = status
      @method = method
      @url = url
      @body = body
      @headers = headers
    end
  end

  # Raised for 4xx responses (excluding 429).
  class ClientError < RequestError; end

  # Raised for HTTP 429 responses (rate limiting).
  class RateLimitedError < RequestError; end

  # Raised for 5xx responses.
  class ServerError < RequestError; end

  # Raised when the request times out.
  class TimeoutError < RequestError; end

  # Raised when Faraday cannot establish a connection.
  class ConnectionFailedError < RequestError; end

  # Raised when JSON parsing fails for a successful response.
  class ParseError < RequestError; end
end
