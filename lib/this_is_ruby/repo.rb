# frozen_string_literal: true

require "open3"
require "pathname"

module ThisIsRuby
  # The git working tree under inspection.
  #
  # Only tracked files are considered. Linguist reads the repository, so a
  # path git ignores is already invisible to it and needs no attribute --
  # which is why a project that gitignores `coverage/`, as most do, gets
  # nothing written about it.
  class Repo
    class NotAGitRepo < Error; end

    # Reading a whole blob to look for a marker comment is wasteful, and the
    # markers we check for all sit in the first few lines.
    PEEK_BYTES = 4096

    attr_reader :root

    def self.at(path)
      out, status = Open3.capture2e("git", "-C", path.to_s, "rev-parse", "--show-toplevel")
      raise NotAGitRepo, "not a git repository: #{path}" unless status.success?

      new(out.strip)
    end

    def initialize(root)
      @root = Pathname.new(root).expand_path
    end

    # Returns an Array of repo-relative paths, as git reports them.
    def tracked
      @tracked ||= begin
        out, status = Open3.capture2("git", "-C", root.to_s, "ls-files", "-z")
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

    def size(path)
      full = root.join(path)
      full.file? ? full.size : 0
    end

    private

    def tracked_set
      @tracked_set ||= tracked.to_set
    end
  end
end
