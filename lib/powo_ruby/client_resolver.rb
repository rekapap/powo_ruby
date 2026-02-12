# frozen_string_literal: true

module PowoRuby
  # Resolves a client instance for the module-level API.
  #
  # `config` may be:
  # - nil (use the default, memoized client)
  # - Hash (merge into defaults for this call)
  # - PowoRuby::Configuration
  # - a client instance of the requested klass
  class ClientResolver
    # Resolve a client instance based on the `config` argument.
    #
    # @param klass [Class] client class to construct (usually {PowoRuby::Client})
    # @param config [nil, Hash, PowoRuby::Configuration, Object] see class docstring
    # @param memo_key [Symbol] thread-local key used for memoization when config is nil
    # @param default_overrides [Hash] overrides always applied when building new instances
    # @return [Object] instance of `klass`
    def self.resolve(klass, config:, memo_key:, default_overrides: {})
      return config if config.is_a?(klass)

      return klass.new(options: PowoRuby.config.with(config).client_kwargs, **default_overrides) if config.is_a?(Hash)

      return klass.new(options: config.client_kwargs, **default_overrides) if config.is_a?(Configuration)

      if config.nil?
        return Thread.current[memo_key] ||= klass.new(options: PowoRuby.config.client_kwargs,
                                                      **default_overrides)
      end

      raise ArgumentError, "config must be nil, a Hash, PowoRuby::Configuration, or #{klass}"
    end
  end
end
