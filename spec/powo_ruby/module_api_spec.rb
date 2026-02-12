# frozen_string_literal: true

require "spec_helper"

RSpec.describe "convenience client API" do
  let(:base_url) { "https://powo.science.kew.org/api/2" }
  let(:other_base_url) { "https://example.test/api/2" }

  before do
    PowoRuby.reset_clients!
    PowoRuby.configure do |c|
      c.base_url = base_url
    end
  end

  it "supports PowoRuby.powo.search.query" do
    stub_request(:get, "#{base_url}/search")
      .with(
        query: { "q" => "Acacia", "cursor" => "*", "perPage" => "24" },
        headers: {
          "Accept" => "application/json",
          "User-Agent" => %r{powo_ruby/#{Regexp.escape(PowoRuby::VERSION)}}
        }
      )
      .to_return(status: 200, body: JSON.dump({ "results" => [], "page" => 1, "totalPages" => 0 }), headers: {})

    expect(response).to be_a(PowoRuby::Response)
  end

  let(:response) { PowoRuby.powo.search.query(query: "Acacia") }

  it "supports per-call config override" do
    stub_request(:get, "#{other_base_url}/search")
      .with(query: { "q" => "Acacia", "cursor" => "*", "perPage" => "24" })
      .to_return(status: 200, body: JSON.dump({ "results" => [], "page" => 1, "totalPages" => 0 }), headers: {})

    expect(other_response).to be_a(PowoRuby::Response)
  end

  let(:other_response) { PowoRuby.powo(config: { base_url: other_base_url }).search.query(query: "Acacia") }

  it "supports PowoRuby.ipni.search with IPNI allow-list" do
    stub_request(:get, "#{base_url}/search")
      .with(query: hash_including("q" => "Poa annua", "family" => "Poaceae", "cursor" => "*", "perPage" => "24"))
      .to_return(status: 200, body: JSON.dump({ "results" => [], "page" => 1, "totalPages" => 0 }), headers: {})

    expect(ipni_response).to be_a(PowoRuby::Response)
  end

  let(:ipni_response) { PowoRuby.ipni.search.query(query: "Poa annua", filters: { family: "Poaceae" }) }
end
