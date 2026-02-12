# frozen_string_literal: true

require_relative "powo_ruby/version"
require_relative "powo_ruby/errors"
require_relative "powo_ruby/validation"
require_relative "powo_ruby/uri_utils"
require_relative "powo_ruby/request"
require_relative "powo_ruby/response"
require_relative "powo_ruby/terms"
require_relative "powo_ruby/configuration"
require_relative "powo_ruby/client_resolver"
require_relative "powo_ruby/paginator"
require_relative "powo_ruby/resources/search"
require_relative "powo_ruby/resources/taxa"
require_relative "powo_ruby/client"

# Unofficial, defensive Ruby client for Plants of the World Online (POWO).
#
# This gem exposes:
# - module-level convenience clients (`PowoRuby.powo`, `PowoRuby.ipni`)
# - a configurable `PowoRuby::Client` with endpoint wrappers (`#search`, `#taxa`)
#
# The underlying POWO API is undocumented and may change. This gem focuses on:
# - validating parameters early
# - providing cursor-based iteration helpers
# - exposing errors with useful context (method/url/status/body)
module PowoRuby
  class << self
    # Global configuration used by the convenience constructors.
    #
    # @return [PowoRuby::Configuration]
    def config
      @config ||= Configuration.new
    end

    # Configure the global `PowoRuby.config`.
    #
    # Calling this also resets any memoized per-thread convenience clients, so new calls
    # to `PowoRuby.powo`/`PowoRuby.ipni` pick up the updated configuration.
    #
    # @yieldparam c [PowoRuby::Configuration]
    # @return [PowoRuby::Configuration] the updated configuration
    #
    # @example
    #   PowoRuby.configure do |c|
    #     c.timeout = 10
    #     c.cache = Rails.cache
    #     c.cache_options = { expires_in: 60 }
    #   end
    def configure
      yield(config)
      reset_clients!
      config
    end

    # Clears memoized convenience clients for the current thread.
    #
    # The convenience clients (`PowoRuby.powo`, `PowoRuby.ipni`) memoize a client per-thread
    # to avoid re-parsing terms and rebuilding Faraday connections.
    #
    # @return [void]
    def reset_clients!
      Thread.current[:powo_ruby_default_powo_client] = nil
      Thread.current[:powo_ruby_default_ipni_client] = nil
    end

    # Convenience constructor for a POWO-mode client.
    #
    # Uses a per-thread memoized client unless `config:` is provided.
    #
    # @param config [nil, Hash, PowoRuby::Configuration, PowoRuby::Client]
    #   - `nil`: use memoized client
    #   - `Hash`: override selected config keys for this call
    #   - `PowoRuby::Configuration`: use exactly that configuration
    #   - `PowoRuby::Client`: returned as-is
    # @return [PowoRuby::Client]
    #
    # @example (default client)
    #   client = PowoRuby.powo
    #   client.search.query(query: "Acacia")
    #
    # @example (override for a single call)
    #   client = PowoRuby.powo(config: { timeout: 2 })
    def powo(config: nil)
      ClientResolver.resolve(
        Client,
        config: config,
        memo_key: :powo_ruby_default_powo_client,
        default_overrides: { mode: :powo }
      )
    end

    # Convenience constructor for an IPNI-mode client.
    #
    # This mode validates parameters against the IPNI allow-list (terms) but still calls
    # the same underlying POWO `/search` and `/taxon/<id>` endpoints.
    #
    # @param config [nil, Hash, PowoRuby::Configuration, PowoRuby::Client] see {#powo}
    # @return [PowoRuby::Client]
    def ipni(config: nil)
      ClientResolver.resolve(
        Client,
        config: config,
        memo_key: :powo_ruby_default_ipni_client,
        default_overrides: { mode: :ipni }
      )
    end
  end
end
