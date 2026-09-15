# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require "this_is_ruby"

# Builds throwaway git repositories. The rules read `git ls-files`, so a
# fixture is only meaningful once it is actually tracked.
module RepoBuilder
  def build_repo(files)
    root = Pathname.new(Dir.mktmpdir("this_is_ruby-spec"))
    created << root
    files.each do |path, contents|
      full = root.join(path)
      full.dirname.mkpath
      full.write(contents)
    end
    git("init", "-q", root.to_s)
    git("-C", root.to_s, "add", "-A", "-f")
    ThisIsRuby::Repo.new(root)
  end

  def created = @created ||= []

  # Deliberately not called `run`: example groups define their own.
  def git(*arguments)
    return if system("git", *arguments, out: File::NULL, err: File::NULL)

    raise "git #{arguments.join(" ")} failed"
  end
end

RSpec.configure do |config|
  config.include RepoBuilder
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.after { created.each { |dir| FileUtils.remove_entry(dir, true) } }
end

RAILS_ERROR_PAGE = <<~HTML
  <!DOCTYPE html>
  <html>
  <!-- This file lives in public/404.html -->
  <body><h1>The page you were looking for doesn't exist.</h1></body>
  </html>
HTML

SIMPLECOV_INDEX = <<~HTML
  <!DOCTYPE html>
  <html xmlns='http://www.w3.org/1999/xhtml'>
    <head>
      <title>Code coverage for My App</title>
      <script src='./assets/0.22.0/application.js' type='text/javascript'></script>
    </head>
  </html>
HTML
