# frozen_string_literal: true

require_relative "lib/powo_ruby/version"

Gem::Specification.new do |spec|
  spec.name = "powo_ruby"
  spec.version = PowoRuby::VERSION
  spec.authors = ["Reka Pap"]
  spec.email = ["rekapap28@gmail.com"]

  spec.summary = "Unofficial Ruby client for Kew POWO (Plants of the World Online) API"
  spec.description = "A small, defensive, unofficial client for the undocumented POWO API."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  # Project links (these should point to YOUR project, not POWO/Kew)
  spec.homepage = "https://github.com/rekapap/powo_ruby"
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/rekapap/powo_ruby/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ examples/ .git appveyor Gemfile])
    end
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 2.0"
end
