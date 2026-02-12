# frozen_string_literal: true

require "spec_helper"

RSpec.describe PowoRuby::Response do
  subject(:response) { described_class.new(raw) }

  context "when results are missing" do
    let(:raw) { { "totalResults" => 123 } }

    it "returns empty results" do
      expect(response.results).to eq([])
    end

    it "exposes total_count from totalResults" do
      expect(response.total_count).to eq(123)
    end

    it "treats missing results as no next page" do
      expect(response.next_page?).to be(false)
    end

    it "enumerates missing results as empty" do
      expect(response.to_a).to eq([])
    end
  end

  context "when results are not an array" do
    let(:raw) { { "results" => { "oops" => true } } }

    it "returns empty results" do
      expect(response.results).to eq([])
    end
  end
end
