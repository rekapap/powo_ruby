# frozen_string_literal: true

require_relative "../response"
require_relative "../validation"

module PowoRuby
  module Resources
    # Endpoint wrapper around POWO's `/search` resource.
    #
    # Responsibilities:
    # - validate user input
    # - shape/normalize params for the API
    # - provide cursor-based enumerators
    #
    # This class is typically accessed via {PowoRuby::Client#search}.
    class Search
      DEFAULT_CURSOR = "*"
      DEFAULT_PER_PAGE = 24

      # @param request [PowoRuby::Request,#get] HTTP adapter used to call the API
      # @param allowed_params [Set<Symbol>] allow-list of supported params for this mode
      # @param group_keys [Array<Symbol>] keys that should be flattened when passed as grouped hashes
      def initialize(request:, allowed_params:, group_keys:)
        @request = request
        @allowed_params = allowed_params
        @group_keys = group_keys
      end

      # Perform a simple text search.
      #
      # @param query [String] the search query (mapped to `q`)
      # @param filters [Hash] optional filter hash (validated against the allow-list)
      # @param cursor [String] POWO cursor for pagination (default `*`)
      # @param per_page [Integer] page size (mapped to `perPage`)
      # @return [PowoRuby::Response]
      #
      # @example
      #   response = client.search.query(query: "Acacia", filters: { accepted: true })
      #   response.total_count
      #   response.results
      def query(query:, filters: {}, cursor: DEFAULT_CURSOR, per_page: DEFAULT_PER_PAGE)
        Validation.presence!(query, name: "query")
        reject_page!(filters)

        params = normalize_filters(filters, name: "filters")
        params["q"] = query.to_s
        params["cursor"] = normalize_cursor(cursor)
        params["perPage"] = Integer(per_page)

        Response.new(request.get("search", params: params))
      end

      # Perform an "advanced" search using a structured hash of terms.
      #
      # Supports both flat and grouped forms; grouped keys are flattened based on `group_keys`.
      #
      # @param params_hash [Hash] query terms / filters
      # @return [PowoRuby::Response]
      #
      # @example (flat)
      #   client.search.advanced(family: "Fabaceae", accepted: true, limit: 24)
      #
      # @example (grouped)
      #   client.search.advanced(
      #     name: { genus: "Acacia", family: "Fabaceae" },
      #     accepted: true
      #   )
      def advanced(params_hash)
        Validation.hash!(params_hash, name: "params_hash")

        flat = flatten_groups(params_hash)
        reject_page!(flat)
        params = normalize_filters(flat, name: "params_hash")

        Response.new(request.get("search", params: params))
      end

      # Enumerate rows across cursor pages for a simple text search.
      #
      # @param query [String]
      # @param filters [Hash]
      # @param cursor [String]
      # @param per_page [Integer]
      # @return [Enumerator<Hash>]
      #
      # @example
      #   client.search.each(query: "Acacia", filters: { accepted: true }).take(50)
      def each(query:, filters: {}, cursor: DEFAULT_CURSOR, per_page: DEFAULT_PER_PAGE)
        Enumerator.new do |y|
          current_cursor = normalize_cursor(cursor)

          loop do
            response = self.query(query: query, filters: filters, cursor: current_cursor, per_page: per_page)
            response.each { |row| y << row }

            break unless response.next_page?

            raw_cursor = response.raw.is_a?(Hash) ? (response.raw["cursor"] || response.raw[:cursor]) : nil
            break if raw_cursor.to_s.strip.empty? || raw_cursor.to_s == DEFAULT_CURSOR

            current_cursor = raw_cursor.to_s
          end
        end
      end

      # Enumerate rows across cursor pages for an advanced search.
      #
      # `limit` is treated as a page-size hint (mapped to `perPage`).
      #
      # @param params_hash [Hash]
      # @return [Enumerator<Hash>]
      def advanced_each(params_hash)
        flat = flatten_groups(params_hash)
        reject_page!(flat)

        initial_cursor = flat.key?(:cursor) ? flat[:cursor].to_s : DEFAULT_CURSOR
        per_page =
          if flat.key?(:perPage)
            Integer(flat[:perPage])
          elsif flat.key?(:limit)
            Integer(flat[:limit])
          else
            DEFAULT_PER_PAGE
          end

        Enumerator.new do |y|
          current_cursor = initial_cursor.to_s.strip.empty? ? DEFAULT_CURSOR : initial_cursor.to_s
          params_for_call = flat.dup
          params_for_call.delete(:cursor)
          params_for_call.delete(:perPage)

          loop do
            response = advanced(params_for_call.merge(cursor: current_cursor, limit: per_page))
            response.each { |row| y << row }

            break unless response.next_page?

            raw_cursor = response.raw.is_a?(Hash) ? (response.raw["cursor"] || response.raw[:cursor]) : nil
            break if raw_cursor.to_s.strip.empty? || raw_cursor.to_s == DEFAULT_CURSOR

            current_cursor = raw_cursor.to_s
          end
        end
      end

      private

      attr_reader :request, :allowed_params, :group_keys

      def reject_page!(hashish)
        return unless hashish.is_a?(Hash)
        return unless hashish.key?(:page) || hashish.key?("page")

        raise ArgumentError,
              "POWO search no longer supports page-based pagination. Remove :page and use :cursor instead."
      end

      def normalize_cursor(cursor)
        cursor.to_s.strip.empty? ? DEFAULT_CURSOR : cursor.to_s
      end

      def flatten_groups(hash)
        Validation.hash!(hash, name: "params_hash")

        flat = {}
        hash.each do |key, value|
          sym_key = key.is_a?(Symbol) ? key : key.to_s.to_sym
          if group_keys.include?(sym_key)
            Validation.hash!(value, name: sym_key.to_s)
            value.each { |k, v| flat[k.to_sym] = v }
          else
            flat[sym_key] = value
          end
        end
        flat
      end

      def normalize_filters(input_hash, name:)
        Validation.hash!(input_hash, name: name)

        unknown =
          input_hash.keys
                    .map { |k| k.is_a?(Symbol) ? k : k.to_s.to_sym }
                    .reject { |k| allowed_params.include?(k) }
        unless unknown.empty?
          supported = allowed_params.to_a.sort.map(&:inspect).join(", ")
          message =
            "Unsupported parameter(s): #{unknown.map(&:inspect).join(", ")}. Supported: [#{supported}]"
          raise ValidationError, message
        end

        normalized = {}
        input_hash.each do |key, value|
          sym_key = key.is_a?(Symbol) ? key : key.to_s.to_sym
          next if value.nil?

          case sym_key
          when :limit
            normalized["perPage"] = Integer(value)
          when :images
            Validation.boolean!(value, name: "images")
            normalized["f"] = "has_images" if value
          when :accepted
            Validation.boolean!(value, name: "accepted")
            normalized["accepted"] = value
          when :page
            normalized["page"] = Integer(value)
          else
            normalized[sym_key.to_s] = value
          end
        end

        normalized
      end
    end
  end
end
