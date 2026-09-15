# frozen_string_literal: true

require_relative "this_is_ruby/version"

# Tells GitHub Linguist which files in a Ruby project nobody actually wrote.
#
# GitHub picks a repository's language by counting bytes, and a Rails app
# carries a lot of bytes it never authored: generated error pages, compiled
# assets, coverage reports, components copied in by a frontend generator.
# Counted together they routinely outweigh the app's own Ruby, and the repo
# is labelled HTML or TypeScript.
#
# Linguist already has the fix, `.gitattributes` overrides, but nobody
# maintains that file by hand. This gem writes it from what is actually on
# disk.
module ThisIsRuby
  class Error < StandardError; end
end

require_relative "this_is_ruby/repo"
require_relative "this_is_ruby/emission"
require_relative "this_is_ruby/rule"
require_relative "this_is_ruby/rules"
require_relative "this_is_ruby/plan"
require_relative "this_is_ruby/attributes_file"
require_relative "this_is_ruby/language_estimate"
require_relative "this_is_ruby/report"
require_relative "this_is_ruby/cli"
