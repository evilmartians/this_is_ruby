# frozen_string_literal: true

require_relative "lib/this_is_ruby/version"

Gem::Specification.new do |spec|
  spec.name = "this_is_ruby"
  spec.version = ThisIsRuby::VERSION
  spec.authors = ["Irina Nazarova"]
  spec.email = ["inazarova@evilmartians.com"]

  spec.summary = "Tell GitHub which files in your Ruby project nobody wrote"
  spec.description = <<~TEXT
    GitHub picks a repository's language by counting bytes, and a Rails app
    carries plenty it never authored: generated error pages, compiled assets,
    coverage reports, components copied in by a frontend generator. Together
    they routinely outweigh the app's own Ruby. this_is_ruby finds them and
    writes the .gitattributes overrides Linguist already understands.
  TEXT
  spec.homepage = "https://github.com/evilmartians/this_is_ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb", "exe/*", "README.md", "CHANGELOG.md", "LICENSE.txt"]
  spec.bindir = "exe"
  spec.executables = ["this_is_ruby"]
  spec.require_paths = ["lib"]
end
