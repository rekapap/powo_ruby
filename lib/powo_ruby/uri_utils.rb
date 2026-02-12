# frozen_string_literal: true

require "uri"

module PowoRuby
  # Small URI helper utilities.
  module URIUtils
    module_function

    # Escape a value for safe inclusion in a URL path segment.
    #
    # This is used for `/taxon/<id>` lookups, where IDs can include characters like `/` or `:`.
    #
    # @param value [String]
    # @return [String]
    def escape_path_segment(value)
      URI::DEFAULT_PARSER.escape(value, /[^A-Za-z0-9\-._~]/)
    end
  end
end
