# frozen_string_literal: true

require "erb"
require "json"
require "sinatra/base"

require "powo_ruby"

class PowoExampleApp < Sinatra::Base
  configure do
    set :root, __dir__
    set :public_folder, File.join(root, "public")
    set :views, File.join(root, "views")
  end

  before do
    # Optional runtime config via env vars
    PowoRuby.configure do |c|
      c.base_url = ENV.fetch("POWO_BASE_URL", c.base_url)
      c.timeout = Integer(ENV.fetch("POWO_TIMEOUT", c.timeout))
      c.open_timeout = Integer(ENV.fetch("POWO_OPEN_TIMEOUT", c.open_timeout))
      c.retries = ENV.fetch("POWO_RETRIES", c.retries ? "true" : "false") == "true"
    end
  rescue ArgumentError => e
    @config_error = e.message
  end

  helpers do
    def h(text)
      Rack::Utils.escape_html(text.to_s)
    end

    def truthy?(value)
      %w[1 true yes on].include?(value.to_s.strip.downcase)
    end

    def parse_filters(params)
      filters = {}

      family = params["family"].to_s.strip
      genus = params["genus"].to_s.strip
      accepted = params["accepted"].to_s.strip

      filters[:family] = family unless family.empty?
      filters[:genus] = genus unless genus.empty?
      filters[:accepted] = truthy?(accepted) if %w[0 1 true false yes no on off].include?(accepted.downcase)

      filters
    end

    # POWO's schema is undocumented and may drift. Try a few common keys.
    def result_identifier(result)
      return nil unless result.is_a?(Hash)

      candidates = [
        result["fqId"],
        result["id"],
        result["taxonID"],
        result["taxonId"],
        result["uri"],
        result.dig("taxon", "fqId"),
        result.dig("taxon", "id")
      ]

      candidates.find { |v| !v.to_s.strip.empty? }
    end

    def result_title(result)
      return result.to_s unless result.is_a?(Hash)

      candidates = [
        result["name"],
        result["scientificName"],
        result["acceptedName"],
        result["displayName"],
        result["author"],
        result_identifier(result)
      ]

      candidates.find { |v| !v.to_s.strip.empty? } || "(unknown)"
    end

    def pretty_json(obj)
      JSON.pretty_generate(obj)
    rescue JSON::GeneratorError
      obj.inspect
    end
  end

  get "/" do
    erb :index
  end

  get "/search" do
    @query = params["q"].to_s.strip
    @cursor = params["cursor"].to_s.strip
    @cursor = "*" if @cursor.empty?
    @prev_cursor = params["prev_cursor"].to_s.strip
    @per_page = (Integer(params["per_page"]) rescue 24)
    @per_page = 24 if @per_page < 1
    @filters = parse_filters(params)

    if @config_error
      status 500
      return erb :search
    end

    if @query.empty?
      @error = "Query is required."
      status 422
      return erb :search
    end

    begin
      @powo_response =
        PowoRuby.powo.search.query(
          query: @query,
          filters: @filters,
          cursor: @cursor,
          per_page: @per_page
        )
      erb :search
    rescue StandardError => e
      @error = "#{e.class}: #{e.message}"
      status 500
      erb :search
    end
  end

  get "/taxon" do
    @id = params["id"].to_s.strip

    if @config_error
      status 500
      return erb :taxon
    end

    if @id.empty?
      @error = "id is required."
      status 422
      return erb :taxon
    end

    begin
      @powo_response = PowoRuby.powo.taxa.lookup(@id)
      erb :taxon
    rescue StandardError => e
      @error = "#{e.class}: #{e.message}"
      status 500
      erb :taxon
    end
  end
end

