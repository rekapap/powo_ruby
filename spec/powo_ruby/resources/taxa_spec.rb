# frozen_string_literal: true

require "spec_helper"

RSpec.describe PowoRuby::Resources::Taxa do
  let(:taxa_fake_request_class) do
    Class.new do
      attr_reader :last_path, :last_params

      def get(path, params:)
        @last_path = path
        @last_params = params
        { "results" => [], "cursor" => "*" }
      end
    end
  end

  let(:request) { taxa_fake_request_class.new }

  subject(:endpoint) { described_class.new(request: request) }

  it "requires id to be present" do
    expect { endpoint.lookup(nil) }.to raise_error(PowoRuby::ValidationError, /id must be provided/)
  end

  it "escapes the taxon id in the request path" do
    endpoint.lookup("a/b:c")
    expect(request.last_path).to eq("taxon/a%2Fb%3Ac")
  end
end
