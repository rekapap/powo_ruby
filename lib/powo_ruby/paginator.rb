# frozen_string_literal: true

module PowoRuby
  # Generic, Response-driven paginator for page-based APIs.
  #
  # POWO primarily uses cursor-based paging for search, but this utility exists as a
  # reusable helper for any endpoints that return {PowoRuby::Response} objects with
  # `#each` and `#next_page?`.
  class Paginator
    # Build an enumerator that fetches pages starting at `start_page`.
    #
    # The block must return a {PowoRuby::Response} (or any object responding to `#each`
    # and `#next_page?`).
    #
    # @param start_page [Integer]
    # @yieldparam page [Integer]
    # @yieldreturn [#each,#next_page?]
    # @return [Enumerator]
    #
    # @example
    #   enum = PowoRuby::Paginator.enumerator do |page|
    #     client.some_endpoint.page(page: page)
    #   end
    def self.enumerator(start_page: 1, &fetch_page)
      raise ArgumentError, "block required" unless fetch_page

      Enumerator.new do |y|
        current_page = Integer(start_page)

        loop do
          response = fetch_page.call(current_page)
          response.each { |row| y << row }

          break unless response.next_page?

          current_page += 1
        end
      end
    end
  end
end
