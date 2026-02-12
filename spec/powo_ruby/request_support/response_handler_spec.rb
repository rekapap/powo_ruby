# frozen_string_literal: true

require "spec_helper"

RSpec.describe PowoRuby::RequestSupport::ResponseHandler do
  let(:response_class) { Struct.new(:status, :body, :headers) }

  let(:handler) { described_class.new }
  let(:method) { :get }
  let(:url) { "https://example.test/api/2/search" }
  let(:status) { 200 }
  let(:body) { "{}" }
  let(:headers) { {} }

  subject(:response) { response_class.new(status, body, headers) }

  context "when rate limited" do
    let(:status) { 429 }
    let(:headers) { { "Retry-After" => "1" } }

    it "raises RateLimitedError for 429" do
      expect { handler.handle(response, method: method, url: url) }.to raise_error(PowoRuby::RateLimitedError)
    end
  end

  context "when server errors" do
    let(:status) { 503 }

    it "raises ServerError for 5xx" do
      expect { handler.handle(response, method: method, url: url) }.to raise_error(PowoRuby::ServerError)
    end
  end

  context "when client errors" do
    let(:status) { 404 }

    it "raises ClientError for 4xx (excluding 429)" do
      expect { handler.handle(response, method: method, url: url) }.to raise_error(PowoRuby::ClientError)
    end
  end

  context "when the body is JSON" do
    let(:body) { '{"ok":true}' }

    it "parses JSON string bodies" do
      expect(handler.handle(response, method: method, url: url)).to eq({ "ok" => true })
    end
  end

  context "when the body is blank" do
    let(:body) { "   " }

    it "returns {} for blank bodies" do
      expect(handler.handle(response, method: method, url: url)).to eq({})
    end
  end

  context "when the body is already a Hash" do
    let(:body) { { "ok" => true } }

    it "returns hashes without parsing" do
      expect(handler.handle(response, method: method, url: url)).to eq(body)
    end
  end

  context "when JSON parsing fails" do
    let(:body) { "{" }

    it "raises ParseError for invalid JSON" do
      expect { handler.handle(response, method: method, url: url) }.to raise_error(PowoRuby::ParseError)
    end
  end
end
