# frozen_string_literal: true

require "spec_helper"
require "set"

RSpec.describe PowoRuby::Resources::Search do
  let(:search_fake_request_class) do
    Class.new do
      attr_reader :last_path, :last_params

      def initialize(&handler)
        @handler = handler
      end

      def get(path, params:)
        @last_path = path
        @last_params = params
        @handler ? @handler.call(path, params) : { "results" => [], "cursor" => "*", "page" => 1, "totalPages" => 0 }
      end
    end
  end

  let(:allowed_params) { Set.new(%i[family accepted images limit cursor perPage q]) }
  let(:group_keys) { %i[name characteristic geography] }
  let(:handler) { nil }

  let(:request) do
    handler ? search_fake_request_class.new(&handler) : search_fake_request_class.new
  end

  subject(:endpoint) { described_class.new(request: request, allowed_params: allowed_params, group_keys: group_keys) }

  it "requires query to be present" do
    expect { endpoint.query(query: nil) }.to raise_error(PowoRuby::ValidationError, /query must be provided/)
  end

  it "rejects page-based pagination filters" do
    expect do
      endpoint.query(query: "x", filters: { page: 1 })
    end.to raise_error(ArgumentError, /no longer supports page-based/i)
  end

  it "rejects unsupported filters" do
    expect do
      endpoint.query(query: "x", filters: { nope: 1 })
    end.to raise_error(PowoRuby::ValidationError, /Unsupported parameter/)
  end

  it "maps images=true to f=has_images" do
    endpoint.query(query: "Acacia", filters: { images: true })
    expect(request.last_params).to eq({ "f" => "has_images", "q" => "Acacia", "cursor" => "*", "perPage" => 24 })
  end

  it "maps limit to perPage for advanced search" do
    endpoint.advanced({ limit: 2 })

    expect(request.last_params).to eq({ "perPage" => 2 })
  end

  context "when flattening grouped params" do
    let(:group_keys) { %i[name] }

    before do
      endpoint.advanced({ name: { family: "Apocynaceae" }, accepted: true })
    end

    it "uses the flattened params" do
      expect(request.last_params).to eq({ "family" => "Apocynaceae", "accepted" => true })
    end
  end

  context "when iterating cursor pagination" do
    let(:calls) { { count: 0 } }
    let(:handler) do
      lambda do |_path, _params|
        calls[:count] += 1
        if calls[:count] == 1
          { "results" => [{ "x" => 1 }],
            "cursor" => "next" }
        else
          { "results" => [{ "x" => 2 }], "cursor" => "*" }
        end
      end
    end

    subject(:rows) { endpoint.each(query: "x", per_page: 2).to_a }

    it "yields results across pages" do
      expect(rows).to eq([{ "x" => 1 }, { "x" => 2 }])
    end
  end

  context "when iterating advanced_each cursor pagination" do
    let(:handler) do
      lambda do |_path, params|
        if params["cursor"] == "*"
          { "results" => [{ "x" => 1 }],
            "cursor" => "next" }
        else
          { "results" => [{ "x" => 2 }], "cursor" => "*" }
        end
      end
    end

    subject(:rows) { endpoint.advanced_each({ limit: 2 }).to_a }

    it "yields results across pages" do
      expect(rows).to eq([{ "x" => 1 }, { "x" => 2 }])
    end
  end

  context "when normalizing page filters directly" do
    let(:allowed_params) { Set.new(%i[family accepted images limit cursor perPage q page]) }

    subject(:normalized) { endpoint.send(:normalize_filters, { page: "2" }, name: "filters") }

    it "normalizes :page to an integer" do
      expect(normalized).to eq({ "page" => 2 })
    end
  end
end
