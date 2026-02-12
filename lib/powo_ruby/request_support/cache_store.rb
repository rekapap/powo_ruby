# frozen_string_literal: true

module PowoRuby
  module RequestSupport
    # Thin adapter around a user-provided cache object.
    #
    # Supports a range of adapters:
    # - Rails cache (`fetch(key, options = nil) { ... }`)
    # - minimal custom caches (`fetch(key) { ... }`)
    #
    # If `cache` does not respond to `fetch`, this acts like a no-op cache and always yields.
    class CacheStore
      # @param cache [Object] cache adapter
      def initialize(cache)
        @cache = cache
      end

      # Fetch a value from the cache (or compute it).
      #
      # @param key [String]
      # @param options [Hash, nil] adapter-specific fetch options (e.g. TTL)
      # @yieldreturn [Object]
      # @return [Object]
      def fetch(key, options = nil, &block)
        return block.call unless @cache.respond_to?(:fetch)

        return @cache.fetch(key, &block) if options.nil? || (options.respond_to?(:empty?) && options.empty?)

        # Prefer passing options (e.g., ActiveSupport::Cache supports `fetch(key, options = nil) { ... }`),
        # but fall back to a plain `fetch(key)` for minimal adapters.
        @cache.fetch(key, options, &block)
      rescue ArgumentError
        @cache.fetch(key, &block)
      end
    end
  end
end
