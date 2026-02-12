# frozen_string_literal: true

require "spec_helper"

RSpec.describe PowoRuby::RequestSupport::CacheKeyBuilder do
  let(:builder) { described_class.new }
  let(:url) { "https://example.test/api/2/search" }
  let(:version) { "1.0.0" }
  let(:namespace) { nil }
  let(:params) { {} }

  subject(:key) do
    builder.build(method: :get, url: url, params: params, namespace: namespace, version: version)
  end

  context "when params are empty" do
    it "omits the query string" do
      expect(key).to eq("powo_ruby v=1.0.0 GET #{url}")
    end
  end

  context "when encoding query params" do
    let(:params) { { q: "a b" } }

    it "URI-encodes query params" do
      expect(key).to eq("powo_ruby v=1.0.0 GET #{url}?q=a+b")
    end
  end

  context "when params are a hash" do
    let(:params) { { b: 2, a: 1 } }

    it "sorts hash keys for stable keys" do
      expect(key).to eq("powo_ruby v=1.0.0 GET #{url}?a=1&b=2")
    end
  end

  context "when params contain arrays" do
    let(:params) { { tag: %w[a b] } }

    it "repeats keys for array values" do
      expect(key).to eq("powo_ruby v=1.0.0 GET #{url}?tag=a&tag=b")
    end
  end

  context "when params contain nested hashes" do
    let(:params) { { a: { b: 1 } } }

    it "supports nested hashes using bracket notation" do
      expect(key).to eq("powo_ruby v=1.0.0 GET #{url}?a%5Bb%5D=1")
    end
  end

  context "when namespace is provided" do
    let(:namespace) { "my_app" }

    it "includes cache namespace in the prefix" do
      expect(key).to eq("powo_ruby ns=my_app v=1.0.0 GET #{url}")
    end
  end
end
