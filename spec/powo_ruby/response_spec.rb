# frozen_string_literal: true

require "spec_helper"

RSpec.describe PowoRuby::Response do
  subject(:response) { described_class.new(raw) }

  let(:raw) { {} }

  context "when raw is not a hash" do
    let(:raw) { "nope" }

    it "returns [] results" do
      expect(response.results).to eq([])
    end
  end

  context "when results are present" do
    let(:raw) { { "results" => [{ "x" => 1 }] } }

    it "returns results from a string-keyed hash" do
      expect(response.results).to eq([{ "x" => 1 }])
    end
  end

  context "when total_count is present" do
    let(:raw) { { "total" => 9 } }

    it "returns total_count from total" do
      expect(response.total_count).to eq(9)
    end
  end

  context "when page metadata is present" do
    let(:raw) { { "page" => 1, "totalPages" => 2, "results" => [] } }

    it "uses page and totalPages for next_page?" do
      expect(response.next_page?).to be(true)
    end
  end

  context "when cursor metadata is present" do
    let(:raw) { { "cursor" => "next", "results" => [] } }

    it "uses cursor for next_page? when page metadata is absent" do
      expect(response.next_page?).to be(true)
    end
  end

  context "when cursor is '*'" do
    let(:raw) { { "cursor" => "*", "results" => [] } }

    it "treats cursor '*' as terminal" do
      expect(response.next_page?).to be(false)
    end
  end
end
