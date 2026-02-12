# frozen_string_literal: true

# rubocop:disable Style/RedundantFetchBlock, Lint/UselessDefaultValueArgument

require "spec_helper"

RSpec.describe PowoRuby::RequestSupport::CacheStore do
  let(:key) { "k" }
  let(:options) { nil }
  let(:adapter) { Object.new }

  subject(:store) { described_class.new(adapter) }

  describe "#fetch" do
    context "when cache does not support fetch" do
      it "yields" do
        expect(store.fetch(key) { :value }).to eq(:value)
      end
    end

    context "when options are nil" do
      let(:adapter) do
        Class.new do
          def fetch(*args)
            args.length
          end
        end.new
      end

      it "calls adapter fetch(key)" do
        expect(store.fetch(key, options) { :ignored }).to eq(1)
      end
    end

    context "when adapter supports options" do
      let(:options) { { expires_in: 1 } }
      let(:adapter) do
        Class.new do
          def fetch(_key, opts = nil)
            opts
          end
        end.new
      end

      it "passes options through to adapter fetch" do
        expect(store.fetch(key, options) { :ignored }).to eq({ expires_in: 1 })
      end
    end

    context "when adapter rejects options" do
      let(:options) { { expires_in: 1 } }
      let(:adapter) do
        Class.new do
          def fetch(_key)
            yield
          end
        end.new
      end

      it "falls back to adapter fetch(key)" do
        expect(store.fetch(key, options) { :ok }).to eq(:ok)
      end
    end
  end
end

# rubocop:enable Style/RedundantFetchBlock, Lint/UselessDefaultValueArgument
