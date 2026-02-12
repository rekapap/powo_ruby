# frozen_string_literal: true

require "spec_helper"

RSpec.describe PowoRuby::Request do
  let(:base_url) { "https://example.test/api/2" }
  let(:user_agent) { "spec-agent" }
  let(:cache) { nil }
  let(:cache_options) { {} }
  let(:cache_namespace) { nil }

  def build_request(**overrides)
    described_class.new(
      user_agent: user_agent,
      base_url: base_url,
      timeout: 1,
      open_timeout: 1,
      max_retries: 0,
      retries: false,
      **overrides
    )
  end

  subject(:request) do
    build_request(cache: cache, cache_options: cache_options, cache_namespace: cache_namespace)
  end

  it "requires base_url" do
    expect do
      described_class.new(
        user_agent: user_agent,
        base_url: "",
        timeout: 1,
        open_timeout: 1,
        max_retries: 0,
        retries: false
      )
    end.to raise_error(PowoRuby::ConfigurationError, /base_url must be provided/)
  end

  it "requires user_agent" do
    expect do
      described_class.new(
        user_agent: " ",
        base_url: base_url,
        timeout: 1,
        open_timeout: 1,
        max_retries: 0,
        retries: false
      )
    end.to raise_error(PowoRuby::ConfigurationError, /user_agent must be provided/)
  end

  context "when a cache adapter short-circuits" do
    let(:cache) { Class.new { def fetch(_key, _options = nil) = :cached }.new }
    let(:cache_options) { { expires_in: 1 } }
    let(:cache_namespace) { "ns" }

    subject(:value) { request.get("search", params: { q: "x" }) }

    it "returns the cached value" do
      expect(value).to eq(:cached)
    end
  end

  context "when Faraday times out" do
    let(:conn) { Class.new { def send(_method) = (raise Faraday::TimeoutError, "timeout") }.new }

    subject(:perform) { -> { request.get("search", params: {}) } }

    before do
      allow(request).to receive(:connection).and_return(conn)
    end

    it "wraps Faraday::TimeoutError as PowoRuby::TimeoutError" do
      expect { perform.call }.to raise_error(PowoRuby::TimeoutError)
    end
  end

  context "when Faraday connection fails" do
    let(:conn) { Class.new { def send(_method) = (raise Faraday::ConnectionFailed, "conn") }.new }

    subject(:perform) { -> { request.get("search", params: {}) } }

    before do
      allow(request).to receive(:connection).and_return(conn)
    end

    it "wraps Faraday::ConnectionFailed as PowoRuby::ConnectionFailedError" do
      expect { perform.call }.to raise_error(PowoRuby::ConnectionFailedError)
    end
  end
end
