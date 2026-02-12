# frozen_string_literal: true

require "spec_helper"

RSpec.describe PowoRuby::RequestSupport::RetryPolicy do
  let(:method) { :get }
  let(:url) { "https://example.test/api/2/search" }
  let(:enabled) { true }
  let(:max_retries) { 1 }
  let(:logger) { nil }

  subject(:policy) do
    described_class.new(enabled: enabled, max_retries: max_retries, backoff_base: 0.0, backoff_max: 0.0, logger: logger)
  end

  context "when retries are disabled" do
    let(:enabled) { false }

    it "re-raises immediately" do
      expect { policy.with_retry(method: method, url: url) { raise PowoRuby::ServerError, "boom" } }
        .to raise_error(PowoRuby::ServerError)
    end
  end

  context "when max retries are exceeded" do
    let(:max_retries) { 0 }

    it "re-raises" do
      expect { policy.with_retry(method: method, url: url) { raise PowoRuby::ServerError, "boom" } }
        .to raise_error(PowoRuby::ServerError)
    end
  end

  context "when enabled and a retry succeeds" do
    let(:logger) { Class.new { def warn(_msg); end }.new }
    let(:attempts) { { count: 0 } }

    subject(:result) do
      policy.with_retry(method: method, url: url) do
        attempts[:count] += 1
        raise PowoRuby::ServerError, "boom" if attempts[:count] == 1

        :ok
      end
    end

    before do
      allow(Kernel).to receive(:sleep)
    end

    it "returns the block result" do
      expect(result).to eq(:ok)
    end
  end

  context "when rate limited and Retry-After is present" do
    let(:attempts) { { count: 0 } }

    subject(:result) do
      policy.with_retry(method: method, url: url) do
        attempts[:count] += 1
        raise PowoRuby::RateLimitedError.new("limited", headers: { "Retry-After" => "0" }) if attempts[:count] == 1

        :ok
      end
    end

    before do
      allow(Kernel).to receive(:sleep)
    end

    it "returns the block result" do
      expect(result).to eq(:ok)
    end
  end
end
