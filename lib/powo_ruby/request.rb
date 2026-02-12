# frozen_string_literal: true

require "faraday"
require "uri"

require_relative "request_support/cache_key_builder"
require_relative "request_support/cache_store"
require_relative "request_support/response_handler"
require_relative "request_support/retry_policy"

module PowoRuby
  # Central HTTP wrapper for POWO requests.
  #
  # Defensive by default:
  # - timeouts
  # - retries with exponential backoff for 429 and 5xx
  # - JSON parsing with helpful errors
  #
  # This class is considered an internal building block; most users will interact with it
  # indirectly via {PowoRuby::Client} and endpoint wrappers.
  class Request
    # @param user_agent [String] sent as the `User-Agent` header
    # @param base_url [String] POWO API base, e.g. `https://powo.science.kew.org/api/2`
    # @param timeout [Numeric] request timeout (seconds)
    # @param open_timeout [Numeric] connection open timeout (seconds)
    # @param max_retries [Integer] number of retries (not counting the first attempt)
    # @param backoff_base [Numeric] base backoff seconds for retries
    # @param backoff_max [Numeric] max backoff seconds for retries
    # @param retries [Boolean] enable/disable retry behavior
    # @param logger [#warn, nil] optional logger
    # @param cache_kwargs [Hash] cache configuration
    # @option cache_kwargs [#fetch, nil] :cache cache adapter (e.g. Rails.cache)
    # @option cache_kwargs [Hash] :cache_options adapter options (e.g. `{ expires_in: 60 }`)
    # @option cache_kwargs [String, nil] :cache_namespace namespace used in cache keys
    def initialize(
      user_agent:,
      base_url:,
      timeout:,
      open_timeout:,
      max_retries:,
      backoff_base: 0.5,
      backoff_max: 8.0,
      retries: true,
      logger: nil,
      **cache_kwargs
    )
      raise ConfigurationError, "base_url must be provided" if base_url.to_s.strip.empty?
      raise ConfigurationError, "user_agent must be provided" if user_agent.to_s.strip.empty?

      allowed_cache_kwargs = %i[cache cache_options cache_namespace]
      unknown_cache_kwargs = cache_kwargs.keys - allowed_cache_kwargs
      unless unknown_cache_kwargs.empty?
        raise ArgumentError, "Unknown Request cache kwargs: #{unknown_cache_kwargs.inspect}"
      end

      @base_url = base_url
      @user_agent = user_agent
      @timeout = timeout
      @open_timeout = open_timeout
      @max_retries = Integer(max_retries)
      @backoff_base = Float(backoff_base)
      @backoff_max = Float(backoff_max)
      @retry_enabled = retries ? true : false
      @logger = logger
      @cache = cache_kwargs[:cache]
      @cache_options = cache_kwargs[:cache_options] || {}
      @cache_namespace = cache_kwargs[:cache_namespace]

      @cache_store = RequestSupport::CacheStore.new(cache)
      @cache_key_builder = RequestSupport::CacheKeyBuilder.new
      @retry_policy =
        RequestSupport::RetryPolicy.new(
          enabled: @retry_enabled,
          max_retries: @max_retries,
          backoff_base: @backoff_base,
          backoff_max: @backoff_max,
          logger: @logger
        )
      @response_handler = RequestSupport::ResponseHandler.new
    end

    attr_reader :base_url, :user_agent, :timeout, :open_timeout, :max_retries, :backoff_base, :backoff_max,
                :retry_enabled, :logger, :cache, :cache_options, :cache_namespace

    # Convenience GET wrapper used by endpoints.
    #
    # @param path [String] endpoint path relative to the base URL (e.g. `"search"`)
    # @param params [Hash] query string params
    # @return [Hash, Array] parsed JSON response
    def get(path, params: {})
      request(:get, path, params: params)
    end

    private

    # ... private helpers ...

    def request(method, path, params:)
      url = build_url(path)
      cache_key =
        @cache_key_builder.build(
          method: method,
          url: url,
          params: params,
          namespace: cache_namespace,
          version: PowoRuby::VERSION
        )

      @cache_store.fetch(cache_key) do
        @retry_policy.with_retry(method: method, url: url) do
          response = connection.send(method) do |req|
            req.url(path)
            req.params.update(stringify_keys(params))
            req.headers["Accept"] = "application/json"
            req.headers["User-Agent"] = user_agent
          end

          @response_handler.handle(response, method: method, url: url)
        end
      end
    rescue Faraday::TimeoutError => e
      raise TimeoutError.new(e.message, method: method, url: url, body: nil)
    rescue Faraday::ConnectionFailed => e
      raise ConnectionFailedError.new(e.message, method: method, url: url, body: nil)
    end

    def connection
      @connection ||= Faraday.new(url: base_url) do |conn|
        conn.options.timeout = timeout
        conn.options.open_timeout = open_timeout
        conn.request :url_encoded
        conn.adapter Faraday.default_adapter
      end
    end

    def build_url(path)
      URI.join(base_url.end_with?("/") ? base_url : "#{base_url}/", path.sub(%r{\A/+}, "")).to_s
    end

    def stringify_keys(hash)
      return {} if hash.nil?

      hash.transform_keys(&:to_s)
    end
  end
end
