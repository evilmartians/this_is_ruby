# frozen_string_literal: true

require "open3"
require "pathname"

module ThisIsRuby
  # The git working tree under inspection.
  #
  # Only tracked files are considered. Linguist reads the repository, so a
  # path git ignores is already invisible to it and needs no attribute.
  # That is why a project that gitignores `coverage/`, as most do, gets
  # nothing written about it.
  class Repo
    class NotAGitRepo < Error; end

    # Reading a whole blob to look for a marker comment is wasteful, and the
    # markers we check for all sit in the first few lines.
    PEEK_BYTES = 4096

    # The attributes that take a file out of GitHub's language statistics.
    LINGUIST_EXCLUSIONS = %w[linguist-generated linguist-vendored linguist-documentation].freeze

    attr_reader :root

    def self.at(path)
      # capture3, not capture2e: git writes warnings and GIT_TRACE output to
      # stderr while still succeeding, and merging them corrupts the path.
      out, _err, status = Open3.capture3("git", "-C", path.to_s, "rev-parse", "--show-toplevel")
      raise NotAGitRepo, "not a git repository: #{path}" unless status.success?

      new(out.strip)
    end

    def initialize(root)
      @root = Pathname.new(root).expand_path
    end

    # Returns an Array of repo-relative paths, as git reports them.
    def tracked
      @tracked ||= begin
        out, _err, status = Open3.capture3("git", "-C", root.to_s, "ls-files", "-z")
        raise NotAGitRepo, "cannot list files in #{root}" unless status.success?

        out.split("\0").reject(&:empty?).freeze
      end
    end

    def tracked?(path)
      tracked_set.include?(path)
    end

    # Returns the first PEEK_BYTES of a tracked file, or nil when it is
    # missing from the working tree (a sparse checkout, say).
    def peek(path)
      full = root.join(path)
      return unless full.file?

      full.open("rb") { |io| io.read(PEEK_BYTES) }
    end

    # Paths git already reports as excluded from Linguist's counts, whoever
    # declared them: our own block, the lines Rails generates, or something
    # written by hand. Resolving the patterns ourselves would mean
    # reimplementing gitignore matching, so ask git, which owns the answer.
    def already_excluded
      @already_excluded ||= begin
        paths = tracked
        paths.empty? ? Set.new : Set.new(check_attr(paths))
      end
    end

    def size(path)
      full = root.join(path)
      full.file? ? full.size : 0
    end

    private

    # `check-attr --stdin -z` reads NUL-separated paths and answers with
    # NUL-separated (path, attribute, value) triples.
    def check_attr(paths)
      out, _err, status = Open3.capture3(
        "git", "-C", root.to_s, "check-attr", "--stdin", "-z", *LINGUIST_EXCLUSIONS,
        stdin_data: paths.join("\0")
      )
      return [] unless status.success?

      out.split("\0").each_slice(3).filter_map { |path, _attribute, value| path if value == "set" }
    end

    def tracked_set
      @tracked_set ||= tracked.to_set
    end
  end
end
