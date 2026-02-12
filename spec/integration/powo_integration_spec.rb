# frozen_string_literal: true

require "spec_helper"

RSpec.describe "POWO integration", :integration do
  let(:client) { PowoRuby::Client.new }
  let(:response) { client.search.query(query: "Acacia", filters: { accepted: true }) }

  it "can query the live API (skipped by default)" do
    skip "Set POWO_INTEGRATION=1 to run live integration tests" unless ENV["POWO_INTEGRATION"] == "1"

    expect(response).to(satisfy do |r|
      r.is_a?(PowoRuby::Response) && (r.total_count.is_a?(Integer) || r.total_count.nil?)
    end)
  end
end
