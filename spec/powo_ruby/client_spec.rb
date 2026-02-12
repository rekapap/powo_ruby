# frozen_string_literal: true

require "spec_helper"

RSpec.describe PowoRuby::Client do
  let(:base_url) { "https://powo.science.kew.org/api/2" }
  let(:client) { described_class.new(base_url: base_url) }

  describe "#search.query" do
    context "basic query" do
      before do
        stub_request(:get, "#{base_url}/search")
          .with(
            query: {
              "q" => "Acacia",
              "cursor" => "*",
              "perPage" => "24"
            },
            headers: {
              "Accept" => "application/json",
              "User-Agent" => %r{powo_ruby/#{Regexp.escape(PowoRuby::VERSION)}}
            }
          )
          .to_return(
            status: 200,
            body: JSON.dump(
              {
                "totalResults" => 1,
                "page" => 1,
                "totalPages" => 1,
                "perPage" => 24,
                "cursor" => "*",
                "results" => [
                  { "name" => "Acacia", "rank" => "Genus", "fqId" => "urn:lsid:ipni.org:names:325783-2" }
                ]
              }
            ),
            headers: { "Content-Type" => "application/json" }
          )
      end

      let(:response) { client.search.query(query: "Acacia") }

      it "returns a Response" do
        expect(response).to be_a(PowoRuby::Response)
      end

      it "exposes total_count" do
        expect(response.total_count).to eq(1)
      end

      it "exposes results length" do
        expect(response.results.length).to eq(1)
      end

      it "reports no next_page" do
        expect(response.next_page?).to be(false)
      end

      it "enumerates results" do
        expect(response.map { |r| r["name"] }).to eq(["Acacia"])
      end
    end

    it "rejects page-based pagination (POWO uses cursor)" do
      expect { client.search.query(query: "Acacia", filters: { page: 1 }) }
        .to raise_error(ArgumentError, /no longer supports page-based pagination/i)
    end

    it "validates unsupported filters" do
      expect { client.search.query(query: "Acacia", filters: { nope: 1 }) }
        .to raise_error(PowoRuby::ValidationError, /Unsupported parameter/)
    end

    context "when images=true" do
      before do
        stub_request(:get, "#{base_url}/search")
          .with(
            query: {
              "q" => "Acacia",
              "f" => "has_images",
              "cursor" => "*",
              "perPage" => "24"
            }
          )
          .to_return(status: 200, body: JSON.dump({ "results" => [], "page" => 1, "totalPages" => 0 }), headers: {})
      end

      let(:response) { client.search.query(query: "Acacia", filters: { images: true }) }

      it "maps images=true to f=has_images" do
        expect(response.results).to eq([])
      end
    end
  end

  describe "#taxa.lookup" do
    let(:id) { "urn:lsid:ipni.org:names:30000618-2" }
    let(:escaped_id) { "urn%3Alsid%3Aipni.org%3Anames%3A30000618-2" }

    before do
      stub_request(:get, "#{base_url}/taxon/#{escaped_id}")
        .to_return(status: 200, body: JSON.dump({ "fqId" => id, "name" => "Acanthaceae" }), headers: {})
    end

    let(:response) { client.taxa.lookup(id) }

    it "looks up a taxon by ID" do
      expect(response.raw["fqId"]).to eq(id)
    end

    it "returns the taxon name" do
      expect(response.raw["name"]).to eq("Acanthaceae")
    end
  end

  describe "#search.advanced" do
    it "supports grouped queries" do
      stub_request(:get, "#{base_url}/search")
        .with(
          query: {
            "family" => "Apocynaceae",
            "accepted" => "true"
          }
        )
        .to_return(status: 200, body: JSON.dump({ "results" => [], "page" => 1, "totalPages" => 0 }), headers: {})

      expect(response).to be_a(PowoRuby::Response)
    end

    let(:response) { client.search.advanced(name: { family: "Apocynaceae" }, accepted: true) }
  end

  describe "#search.each" do
    it "follows cursor pagination until cursor is '*'" do
      stub_request(:get, "#{base_url}/search")
        .with(query: { "q" => "Acacia", "cursor" => "*", "perPage" => "2" })
        .to_return(
          status: 200,
          body: JSON.dump(
            {
              "totalResults" => 4,
              "perPage" => 2,
              "cursor" => "next-cursor",
              "results" => [{ "name" => "A" }, { "name" => "B" }]
            }
          ),
          headers: { "Content-Type" => "application/json" }
        )

      stub_request(:get, "#{base_url}/search")
        .with(query: { "q" => "Acacia", "cursor" => "next-cursor", "perPage" => "2" })
        .to_return(
          status: 200,
          body: JSON.dump(
            {
              "totalResults" => 4,
              "perPage" => 2,
              "cursor" => "*",
              "results" => [{ "name" => "C" }, { "name" => "D" }]
            }
          ),
          headers: { "Content-Type" => "application/json" }
        )

      expect(names).to eq(%w[A B C D])
    end

    let(:names) { client.search.each(query: "Acacia", per_page: 2).map { |r| r["name"] } }
  end
end
