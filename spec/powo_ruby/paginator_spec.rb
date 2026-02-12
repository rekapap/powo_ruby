# frozen_string_literal: true

require "spec_helper"

RSpec.describe PowoRuby::Paginator do
  let(:response_class) do
    Class.new do
      def initialize(rows, next_page)
        @rows = rows
        @next_page = next_page
      end

      def each(&block)
        @rows.each(&block)
      end

      def next_page?
        @next_page
      end
    end
  end

  let(:fetch) do
    lambda do |page|
      case page
      when 1 then response_class.new([1, 2], true)
      when 2 then response_class.new([3], false)
      else response_class.new([], false)
      end
    end
  end

  subject(:enum) { described_class.enumerator(start_page: 1, &fetch) }

  it "requires a block" do
    expect { described_class.enumerator }.to raise_error(ArgumentError, /block required/)
  end

  it "yields rows across pages until next_page? is false" do
    expect(enum.to_a).to eq([1, 2, 3])
  end
end
