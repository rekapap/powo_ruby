# frozen_string_literal: true

require "uri"

module PowoRuby
  module RequestSupport
    # Builds a stable cache key for a request.
    #
    # The goal is:
    # - stable ordering (hash keys sorted)
    # - support nested params (bracket notation)
    # - repeat keys for arrays (k=v1&k=v2)
    class CacheKeyBuilder
      # Build a cache key string.
      #
      # @param method [Symbol, String]
      # @param url [String] fully qualified URL (without query)
      # @param params [Hash] query params
      # @param namespace [String, nil] optional namespace included in the key
      # @param version [String, nil] optional gem version included in the key
      # @return [String]
      def build(method:, url:, params:, namespace: nil, version: nil)
        pairs = flatten_params(stringify_keys(params))
        query = pairs.empty? ? "" : "?#{URI.encode_www_form(pairs)}"

        prefix =
          [
            "powo_ruby",
            (namespace.to_s.strip.empty? ? nil : "ns=#{namespace}"),
            (version.to_s.strip.empty? ? nil : "v=#{version}")
          ].compact.join(" ")

        "#{prefix} #{method.to_s.upcase} #{url}#{query}"
      end

      private

      # @param hash [Hash, nil]
      # @return [Hash]
      def stringify_keys(hash)
        return {} if hash.nil?

        hash.transform_keys(&:to_s)
      end

      # Produces a stable, URI-encodable list of [key, value] pairs.
      # - Hash keys are sorted for stability.
      # - Array values become repeated keys (k=v1&k=v2), preserving array order.
      # - Nested hashes are supported using bracket notation: a[b]=1
      #
      # @param obj [Object]
      # @param prefix [String, nil]
      # @return [Array<Array(String, String)>]
      def flatten_params(obj, prefix = nil)
        case obj
        when nil
          []
        when Hash
          obj
            .sort_by { |k, _| k.to_s }
            .flat_map do |k, v|
              key = prefix ? "#{prefix}[#{k}]" : k.to_s
              flatten_params(v, key)
            end
        when Array
          obj.flat_map do |v|
            # If no prefix, we can't encode a value without a key.
            next [] if prefix.nil?

            flatten_params(v, prefix)
          end
        else
          return [] if prefix.nil?

          [[prefix.to_s, obj.to_s]]
        end
      end
    end
  end
end
