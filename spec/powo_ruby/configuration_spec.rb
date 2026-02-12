# frozen_string_literal: true

require "spec_helper"

RSpec.describe PowoRuby::Configuration do
  it "has a default base_url" do
    expect(described_class.new.base_url).to eq("https://powo.science.kew.org/api/2")
  end

  it "includes cache_options in client_kwargs" do
    expect(described_class.new.client_kwargs[:cache_options]).to eq({})
  end

  it "applies overrides using with" do
    expect(config.base_url).to eq("https://example.test/api/2")
  end

  it "rejects unknown keys in with" do
    expect { described_class.new.with(nope: 1) }.to raise_error(ArgumentError, /Unknown configuration key/)
  end

  let(:config) { described_class.new.with(base_url: "https://example.test/api/2") }
end
