# frozen_string_literal: true

module PowoRuby
  # Schema-flexible wrapper for POWO JSON responses.
  #
  # For search-like responses this exposes `results`, `total_count`, and pagination helpers.
  #
  # Note: POWO's API schema is not formally documented; this class keeps parsing conservative.
  class Response
    include Enumerable

    # @param raw [Hash, Array, Object] parsed JSON (or already-decoded object) from the API
    def initialize(raw)
      @raw = raw
    end

    attr_reader :raw

    # Array of result rows for search-like responses.
    #
    # @return [Array<Hash>]
    def results
      if raw.is_a?(Hash)
        value =
          raw["results"] || raw[:results]
      end

      value.is_a?(Array) ? value : []
    end

    # Total result count when present.
    #
    # POWO sometimes returns different keys depending on the endpoint / mode.
    #
    # @return [Integer, nil]
    def total_count
      return nil unless raw.is_a?(Hash)

      raw["totalResults"] || raw[:totalResults] || raw["total"] || raw[:total]
    end

    # Whether another page is available.
    #
    # Supports both styles:
    # - page/totalPages (legacy/page-based)
    # - cursor-based paging (POWO search)
    #
    # @return [Boolean]
    def next_page?
      return false unless raw.is_a?(Hash)

      page = raw["page"] || raw[:page]
      total_pages = raw["totalPages"] || raw[:totalPages] || raw["pages"] || raw[:pages]
      cursor = raw["cursor"] || raw[:cursor]

      if page && total_pages
        page.to_i < total_pages.to_i
      elsif cursor
        cursor.to_s != "*" && !cursor.to_s.empty?
      else
        false
      end
    end

    def each(&block)
      return enum_for(:each) unless block

      results.each(&block)
    end
  end
end
