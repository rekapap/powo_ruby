# frozen_string_literal: true

require "spec_helper"

RSpec.describe PowoRuby::RequestError do
  let(:error) do
    described_class.new(
      "msg",
      status: 400,
      method: :get,
      url: "https://example.test",
      body: "body",
      headers: { "x" => "y" }
    )
  end

  it "exposes status" do
    expect(error.status).to eq(400)
  end

  it "exposes method" do
    expect(error.method).to eq(:get)
  end

  it "exposes url" do
    expect(error.url).to eq("https://example.test")
  end

  it "exposes body" do
    expect(error.body).to eq("body")
  end

  it "exposes headers" do
    expect(error.headers).to eq({ "x" => "y" })
  end
end
