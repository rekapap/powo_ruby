# frozen_string_literal: true

module PowoRuby
  # Main POWO client.
  #
  # Public API is endpoint-oriented (e.g. `client.search.query`, `client.taxa.lookup`).
  #
  # In most cases you won't instantiate this directly; prefer `PowoRuby.powo` / `PowoRuby.ipni`.
  #
  # @example
  #   client = PowoRuby.powo
  #   response = client.search.query(query: "Acacia", filters: { accepted: true })
  #   response.results.first #=> Hash
  class Client
    OPTION_KEYS =
      %i[
        base_url
        timeout
        open_timeout
        max_retries
        retries
        logger
        cache
        cache_options
        cache_namespace
        user_agent
        terms_path
      ].freeze

    # Create a client instance.
    #
    # @param mode [Symbol, String] `:powo` or `:ipni` (controls allowed params and grouping)
    # @param options [Hash, nil] base option hash (usually from {PowoRuby::Configuration#client_kwargs})
    # @param overrides [Hash] per-instance overrides merged into options
    #
    # Supported keys are listed in `OPTION_KEYS`. Unknown keys raise `ArgumentError`.
    #
    # @return [PowoRuby::Client]
    def initialize(
      mode: :powo,
      options: nil,
      **overrides
    )
      @mode = mode.to_sym
      opts = merge_options(options, overrides)
      @terms = Terms.load(opts.fetch(:terms_path))

      @request = Request.new(
        user_agent: opts.fetch(:user_agent),
        base_url: opts.fetch(:base_url),
        timeout: opts.fetch(:timeout),
        open_timeout: opts.fetch(:open_timeout),
        max_retries: opts.fetch(:max_retries),
        retries: opts.fetch(:retries),
        logger: opts.fetch(:logger),
        cache: opts.fetch(:cache),
        cache_options: opts.fetch(:cache_options),
        cache_namespace: opts.fetch(:cache_namespace)
      )
    end

    # Access the `/search` endpoint wrapper.
    #
    # @return [PowoRuby::Resources::Search]
    def search
      @search ||= Resources::Search.new(request: request, allowed_params: allowed_params, group_keys: group_keys)
    end

    # Access the `/taxon/<id>` endpoint wrapper.
    #
    # @return [PowoRuby::Resources::Taxa]
    def taxa
      @taxa ||= Resources::Taxa.new(request: request)
    end

    private

    attr_reader :request, :terms

    def merge_options(options, overrides)
      base = PowoRuby.config.client_kwargs
      merged = base.merge(normalize_options_hash(options)).merge(normalize_options_hash(overrides))
      unknown = merged.keys - OPTION_KEYS
      raise ArgumentError, "Unknown client option keys: #{unknown.inspect}" unless unknown.empty?

      merged
    end

    def normalize_options_hash(hash)
      return {} if hash.nil?
      raise ArgumentError, "options must be a Hash" unless hash.is_a?(Hash)

      hash.each_with_object({}) do |(k, v), out|
        key = k.is_a?(String) || k.is_a?(Symbol) ? k.to_sym : k
        out[key] = v
      end
    end

    def allowed_params
      case @mode
      when :powo
        terms.powo_allowed_params
      when :ipni
        terms.ipni_allowed_params
      else
        raise ArgumentError, "Unknown client mode: #{@mode.inspect} (expected :powo or :ipni)"
      end
    end

    def group_keys
      case @mode
      when :powo
        %i[name characteristic geography]
      when :ipni
        %i[name author publication]
      else
        raise ArgumentError, "Unknown client mode: #{@mode.inspect} (expected :powo or :ipni)"
      end
    end
  end
end
