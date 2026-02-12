# frozen_string_literal: true

require_relative "../errors"

module PowoRuby
  module RequestSupport
    # Encapsulates retry behavior for HTTP calls.
    #
    # This is used by {PowoRuby::Request} to retry on:
    # - {PowoRuby::RateLimitedError} (HTTP 429)
    # - {PowoRuby::ServerError} (HTTP 5xx)
    #
    # Retries use exponential backoff with a small jitter and respect `Retry-After` when present.
    class RetryPolicy
      # @param enabled [Boolean] enable retry behavior
      # @param max_retries [Integer] number of retries (not counting the first attempt)
      # @param backoff_base [Numeric] base seconds for backoff
      # @param backoff_max [Numeric] max seconds for backoff
      # @param logger [#warn, nil] optional logger
      def initialize(enabled:, max_retries:, backoff_base:, backoff_max:, logger: nil)
        @enabled = enabled ? true : false
        @max_retries = Integer(max_retries)
        @backoff_base = Float(backoff_base)
        @backoff_max = Float(backoff_max)
        @logger = logger
      end

      # Execute a block with retry logic.
      #
      # @param method [Symbol, String]
      # @param url [String]
      # @yieldreturn [Object]
      # @return [Object]
      def with_retry(method:, url:)
        attempt = 0
        max_attempts = @max_retries + 1

        begin
          attempt += 1
          yield
        rescue RateLimitedError, ServerError => e
          raise e unless @enabled
          raise e if attempt >= max_attempts

          sleep_seconds = retry_sleep_seconds(e, attempt: attempt)
          warn_log(
            "Retrying #{method.to_s.upcase} #{url} in #{format("%.2f", sleep_seconds)}s " \
            "(attempt #{attempt}/#{max_attempts})"
          )
          sleep(sleep_seconds)
          retry
        end
      end

      private

      def warn_log(message)
        return unless @logger
        return unless @logger.respond_to?(:warn)

        @logger.warn(message)
      end

      def retry_sleep_seconds(error, attempt:)
        header_seconds = retry_after_seconds(error)
        return header_seconds if header_seconds

        # Exponential backoff with small jitter.
        exp = @backoff_base * (2**(attempt - 1))
        jitter = rand * 0.25
        [exp + jitter, @backoff_max].min
      end

      def retry_after_seconds(error)
        return nil unless error.is_a?(RateLimitedError)

        raw = error.headers && (error.headers["retry-after"] || error.headers["Retry-After"])
        return nil if raw.to_s.strip.empty?

        Float(raw)
      rescue ArgumentError
        nil
      end
    end
  end
end
