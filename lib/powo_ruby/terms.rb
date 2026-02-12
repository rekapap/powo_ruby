# frozen_string_literal: true

require "set"

module PowoRuby
  # Loads and exposes allow-lists of supported query parameters for POWO and IPNI.
  #
  # The allow-lists can be sourced from `docs/POWO_SEARCH_TERMS.md` (parsed at runtime) or,
  # if that file can't be read, from built-in fallback lists.
  class Terms
    # Internal helper for allowed POWO/IPNI parameters.
    POWO_NAME = %i[
      full_name scientific_name genus species infraspecific family common_name author rank status
    ].freeze
    POWO_CHARACTERISTIC = %i[
      summary appearance flower fruit leaf habit habitat use conservation
    ].freeze
    POWO_GEOGRAPHY = %i[
      distribution native_distribution introduced_distribution region continent country
    ].freeze
    POWO_ADDITIONAL = %i[
      accepted images page limit sort
    ].freeze

    IPNI_NAME = %i[
      genus species infraspecific_rank infraspecific_name family publication_year full_name
    ].freeze
    IPNI_AUTHOR = %i[
      author standard_form collaboration
    ].freeze
    IPNI_PUBLICATION = %i[
      publication_title publication_year publication_place publisher
    ].freeze

    POWO_GROUP_HEADERS = {
      "name terms" => :name,
      "characteristic terms" => :characteristic,
      "geography terms" => :geography,
      "additional filters" => :additional
    }.freeze

    IPNI_GROUP_HEADERS = {
      "name terms" => :name,
      "author terms" => :author,
      "publication terms" => :publication
    }.freeze

    # Load terms from a markdown file when possible, otherwise fall back to defaults.
    #
    # @param path [String] path to `POWO_SEARCH_TERMS.md`
    # @return [PowoRuby::Terms]
    def self.load(path)
      parsed = parse_markdown(path)
      parsed || new(source_path: path)
    end

    # Parse a terms markdown file.
    #
    # @param path [String]
    # @return [PowoRuby::Terms, nil] nil if unreadable/empty
    def self.parse_markdown(path)
      return nil unless path && File.file?(path)

      content = File.read(path)
      return nil if content.strip.empty?

      section = :powo
      group = nil

      powo = Hash.new { |h, k| h[k] = [] }
      ipni = Hash.new { |h, k| h[k] = [] }

      content.each_line do |line|
        line = line.strip
        next if line.empty?

        if line == "# IPNI Search Terms"
          section = :ipni
          group = nil
          next
        end

        if line.start_with?("## ")
          header = line.delete_prefix("## ").downcase
          group =
            if section == :powo
              POWO_GROUP_HEADERS[header]
            else
              IPNI_GROUP_HEADERS[header]
            end
          next
        end

        next unless line.start_with?("- ")
        next unless group

        term = line.delete_prefix("- ").strip
        term = term.split(/\s+/).first
        next if term.nil? || term.empty?

        sym = term.downcase.to_sym
        if section == :powo
          powo[group] << sym
        else
          ipni[group] << sym
        end
      end

      new(
        source_path: path,
        powo: powo.transform_values { |v| v.uniq.freeze }.freeze,
        ipni: ipni.transform_values { |v| v.uniq.freeze }.freeze
      )
    rescue Errno::ENOENT, Errno::EACCES
      nil
    end

    def initialize(source_path:, powo: nil, ipni: nil)
      @source_path = source_path
      @powo = powo || {
        name: POWO_NAME,
        characteristic: POWO_CHARACTERISTIC,
        geography: POWO_GEOGRAPHY,
        additional: POWO_ADDITIONAL
      }.freeze
      @ipni = ipni || {
        name: IPNI_NAME,
        author: IPNI_AUTHOR,
        publication: IPNI_PUBLICATION
      }.freeze
    end

    attr_reader :source_path

    # Allow-list of supported POWO params as symbols.
    #
    # @return [Set<Symbol>]
    def powo_allowed_params
      @powo.values.flatten.to_set
    end

    # Allow-list of supported IPNI params as symbols.
    #
    # @return [Set<Symbol>]
    def ipni_allowed_params
      @ipni.values.flatten.to_set
    end
  end
end
