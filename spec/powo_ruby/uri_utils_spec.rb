# frozen_string_literal: true

require "spec_helper"

RSpec.describe PowoRuby::URIUtils do
  it "escapes reserved characters in path segments" do
    expect(described_class.escape_path_segment("a/b:c")).to eq("a%2Fb%3Ac")
  end
end
