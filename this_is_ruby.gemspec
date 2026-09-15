# frozen_string_literal: true

require_relative "lib/this_is_ruby/version"

Gem::Specification.new do |spec|
  spec.name = "this_is_ruby"
  spec.version = ThisIsRuby::VERSION
  spec.authors = ["Irina Nazarova"]
  spec.email = ["inazarova@evilmartians.com"]

  spec.summary = "Tell GitHub your project is Ruby."
  # Kept as two paragraphs of unbroken sentences: RubyGems renders the
  # description verbatim, so source-level wrapping shows up on the gem page.
  spec.description = [
    "Ruby is one of the most eloquent and efficient languages, but it gets " \
    "punished for it by GitHub's language attribution. Even more so, a Rails " \
    "app, carefully designed to require next to no boilerplate code, easily " \
    "ends up with less Ruby than JS, TS or HTML (ERB).",
    "This gem tells GitHub: this is Ruby, by marking your frontend as " \
    "\"linguist-vendored\". No side effects on diffs or other DX."
  ].join("\n\n")
  spec.homepage = "https://github.com/evilmartians/this_is_ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb", "exe/*", "README.md", "CHANGELOG.md", "LICENSE.txt"]
  spec.bindir = "exe"
  spec.executables = ["this_is_ruby"]
  spec.require_paths = ["lib"]
end
