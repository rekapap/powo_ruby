# frozen_string_literal: true

require "spec_helper"

RSpec.describe PowoRuby do
  it "exposes a Configuration via config" do
    expect(described_class.config).to be_a(PowoRuby::Configuration)
  end

  it "resets memoized clients when configured" do
    first_client
    expect(second_client).not_to be(first_client)
  end

  it "builds an IPNI client via ipni" do
    described_class.reset_clients!
    expect(described_class.ipni).to be_a(PowoRuby::Client)
  end

  let(:first_client) do
    described_class.reset_clients!
    described_class.powo
  end

  let(:second_client) do
    described_class.configure { |c| c.timeout = (c.timeout || 0) + 1 }
    described_class.powo
  end
end
