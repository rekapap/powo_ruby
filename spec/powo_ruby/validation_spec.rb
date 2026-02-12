# frozen_string_literal: true

require "spec_helper"

RSpec.describe PowoRuby::Validation do
  it "raises when presence! is given nil" do
    expect { described_class.presence!(nil, name: "x") }.to raise_error(PowoRuby::ValidationError, /x must be provided/)
  end

  it "raises when hash! is given a non-hash" do
    expect { described_class.hash!("nope", name: "x") }.to raise_error(PowoRuby::ValidationError, /x must be a Hash/)
  end

  it "raises when boolean! is given a non-boolean" do
    expect { described_class.boolean!("true", name: "x") }
      .to raise_error(PowoRuby::ValidationError, /x must be boolean/)
  end
end
