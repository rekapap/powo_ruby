# frozen_string_literal: true

require "spec_helper"

RSpec.describe PowoRuby::Client do
  it "rejects non-hash options" do
    expect { described_class.new(options: 123) }.to raise_error(ArgumentError, /options must be a Hash/)
  end

  it "rejects unknown option keys" do
    expect { described_class.new(options: { nope: 1 }) }.to raise_error(ArgumentError, /Unknown client option keys/)
  end

  it "accepts string keys in options" do
    expect(client).to be_a(described_class)
  end

  let(:client) { described_class.new(options: { "timeout" => 1 }) }
end
