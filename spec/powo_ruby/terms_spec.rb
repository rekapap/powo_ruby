# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe PowoRuby::Terms do
  describe ".parse_markdown" do
    subject(:terms) { described_class.parse_markdown(path) }

    context "when the file is missing" do
      let(:path) { "/no/such/file.md" }

      it "returns nil" do
        expect(terms).to be_nil
      end
    end

    context "when parsing POWO terms" do
      let(:markdown) do
        <<~MD
          ## Name Terms
          - family (plant family)
        MD
      end

      let!(:file) do
        Tempfile.new(["powo_terms", ".md"]).tap do |f|
          f.write(markdown)
          f.flush
        end
      end

      let(:path) { file.path }

      after do
        file.close!
      end

      it "includes family in powo_allowed_params" do
        expect(terms.powo_allowed_params.include?(:family)).to be(true)
      end
    end

    context "when parsing IPNI terms after the IPNI section header" do
      let(:markdown) do
        <<~MD
          ## Name Terms
          - family

          # IPNI Search Terms
          ## Name Terms
          - genus
        MD
      end

      let!(:file) do
        Tempfile.new(["powo_terms", ".md"]).tap do |f|
          f.write(markdown)
          f.flush
        end
      end

      let(:path) { file.path }

      after do
        file.close!
      end

      it "includes genus in ipni_allowed_params" do
        expect(terms.ipni_allowed_params.include?(:genus)).to be(true)
      end
    end
  end

  describe ".load" do
    subject(:terms) { described_class.load(path) }

    context "when the file is missing" do
      let(:path) { "/no/such/file.md" }

      it "falls back to defaults" do
        expect(terms).to be_a(described_class)
      end
    end
  end
end
