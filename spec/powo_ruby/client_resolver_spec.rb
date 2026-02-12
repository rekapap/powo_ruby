# frozen_string_literal: true

require "spec_helper"

RSpec.describe PowoRuby::ClientResolver do
  let(:klass) { PowoRuby::Client }
  let(:memo_key) { :powo_ruby_test_memo_client }
  let(:default_overrides) { {} }

  before do
    Thread.current[memo_key] = nil
  end

  it "returns a provided client instance unchanged" do
    expect(described_class.resolve(klass, config: client_instance, memo_key: memo_key,
                                          default_overrides: default_overrides))
      .to be(client_instance)
  end

  it "memoizes the default client when config is nil" do
    first_client
    expect(second_client).to be(first_client)
  end

  it "builds a client when config is a Hash" do
    expect(hash_client).to be_a(klass)
  end

  it "builds a client when config is a Configuration" do
    expect(config_client).to be_a(klass)
  end

  it "rejects unsupported config types" do
    expect { described_class.resolve(klass, config: 123, memo_key: memo_key, default_overrides: {}) }
      .to raise_error(ArgumentError, /config must be nil/)
  end

  let(:client_instance) { klass.new }

  let(:first_client) do
    described_class.resolve(klass, config: nil, memo_key: memo_key, default_overrides: default_overrides)
  end

  let(:second_client) do
    described_class.resolve(klass, config: nil, memo_key: memo_key, default_overrides: default_overrides)
  end

  let(:hash_client) do
    described_class.resolve(
      klass,
      config: { base_url: "https://example.test/api/2" },
      memo_key: memo_key,
      default_overrides: default_overrides
    )
  end

  let(:config) { PowoRuby::Configuration.new.with(base_url: "https://example.test/api/2") }

  let(:config_client) do
    described_class.resolve(klass, config: config, memo_key: memo_key, default_overrides: default_overrides)
  end
end
