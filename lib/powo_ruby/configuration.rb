# frozen_string_literal: true

module PowoRuby
  # Global configuration for the convenience constructors (`PowoRuby.powo`, `PowoRuby.ipni`).
  #
  # Users can override defaults via:
  #
  #   PowoRuby.configure do |c|
  #     c.base_url = "..."
  #     c.timeout = 5
  #   end
  #
  class Configuration
    attr_accessor :base_url, :timeout, :open_timeout, :max_retries, :retries, :logger,
                  :cache, :cache_options, :cache_namespace,
                  :user_agent, :terms_path

    def initialize
      @base_url = "https://powo.science.kew.org/api/2"
      @timeout = 10
      @open_timeout = 5
      @max_retries = 3

      @retries = true
      @logger = nil
      @cache = nil
      @cache_options = {}
      @cache_namespace = nil
      @user_agent = "powo_ruby/#{PowoRuby::VERSION}"
      @terms_path = File.expand_path("../../../docs/POWO_SEARCH_TERMS.md", __dir__)
    end

    # Keyword arguments used to build a {PowoRuby::Client}/{PowoRuby::Request}.
    #
    # @return [Hash] normalized options hash suitable for `Client.new(options: ...)`
    def client_kwargs
      {
        base_url: base_url,
        timeout: timeout,
        open_timeout: open_timeout,
        max_retries: max_retries,
        retries: retries,
        logger: logger,
        cache: cache,
        cache_options: cache_options,
        cache_namespace: cache_namespace,
        user_agent: user_agent,
        terms_path: terms_path
      }
    end

    # Returns a copy of this configuration with selected overrides applied.
    #
    # This is used internally when `PowoRuby.powo(config: { ... })` is called.
    #
    # @param overrides [Hash{Symbol,String => Object}]
    # @return [PowoRuby::Configuration]
    def with(overrides)
      dup.tap do |copy|
        overrides.each do |k, v|
          writer = "#{k}="
          raise ArgumentError, "Unknown configuration key: #{k.inspect}" unless copy.respond_to?(writer)

          copy.public_send(writer, v)
        end
      end
    end
  end
end
