# frozen_string_literal: true

require_relative "../response"
require_relative "../uri_utils"
require_relative "../validation"

module PowoRuby
  module Resources
    # Endpoint wrapper around POWO's `/taxon/<id>` resource.
    #
    # This class is typically accessed via {PowoRuby::Client#taxa}.
    class Taxa
      # @param request [PowoRuby::Request,#get] HTTP adapter used to call the API
      def initialize(request:)
        @request = request
      end

      # Lookup a taxon (or IPNI record) by its identifier.
      #
      # The id is URL-escaped before being inserted into the path.
      #
      # @param id [String] POWO/IPNI identifier (often a URN/LSID)
      # @return [PowoRuby::Response]
      #
      # @example
      #   response = client.taxa.lookup("urn:lsid:ipni.org:names:30000618-2")
      #   response.raw #=> Hash
      def lookup(id)
        Validation.presence!(id, name: "id")
        taxon_id = URIUtils.escape_path_segment(id.to_s)

        Response.new(@request.get("taxon/#{taxon_id}", params: {}))
      end
    end
  end
end
