# frozen_string_literal: true

module ThisIsRuby
  # Reads and rewrites .gitattributes, touching only the block it owns.
  #
  # Everything outside the markers is preserved: Rails writes its own lines
  # there, and so do people. The block is rewritten where it already sits, so
  # what someone put below it stays below it.
  class AttributesFile
    BEGIN_MARKER = "# --- this_is_ruby: begin ---"
    END_MARKER = "# --- this_is_ruby: end ---"
    BLOCK = /^#{Regexp.escape(BEGIN_MARKER)}\n.*?^#{Regexp.escape(END_MARKER)}\n?/m

    PREAMBLE = [
      "# Managed by this_is_ruby. Re-run it when your build setup changes.",
      "# Every path below is excluded from this repository's language stats.",
      "# Edit above or below this block, never inside it."
    ].freeze

    attr_reader :path

    def initialize(path)
      @path = Pathname.new(path)
    end

    def current = path.file? ? path.read : ""

    # Patterns already declared outside our block, as pattern => attributes.
    #
    # Attributes keep their `-` or `!` prefix: an owner who wrote
    # `public/404.html -linguist-generated` has spoken about that path just as
    # deliberately as one who set it, and Plan reads both as "leave it alone".
    def existing_attributes
      before, after = split
      "#{before}#{after}".each_line.with_object({}) do |line, declared|
        body = line.split("#", 2).first.to_s.strip
        next if body.empty?

        pattern, *attributes = body.split(/\s+/)
        (declared[pattern] ||= []).concat(attributes)
      end
    end

    def render(emissions)
      before, after = split
      join(before, emissions.empty? ? nil : block(emissions), after)
    end

    def stale?(emissions) = render(emissions) != current

    # Writes the file when the rendering differs, and says whether it did.
    def write(emissions)
      contents = render(emissions)
      return false if contents == current

      path.write(contents)
      true
    end

    private

    # The file around our block. With no block, all of it is "before".
    def split
      match = BLOCK.match(current)
      match ? [match.pre_match, match.post_match] : [current, ""]
    end

    def block(emissions)
      body = "#{BEGIN_MARKER}\n"
      PREAMBLE.each { |line| body << line << "\n" }
      emissions.chunk_while { |a, b| a.rule == b.rule }.each do |group|
        body << "\n# #{group.first.rule.summary}\n"
        group.each { |emission| body << emission.line << "\n" }
      end
      body << END_MARKER << "\n"
    end

    def join(*sections)
      sections.compact.map { |section| tidy(section) }.reject(&:empty?).join("\n")
    end

    # One trailing newline and no leading blank lines, so the sections join
    # with exactly one blank line between them however the file arrived.
    def tidy(text)
      trimmed = text.sub(/\A\n+/, "").sub(/\n*\z/, "")
      trimmed.empty? ? "" : "#{trimmed}\n"
    end
  end
end
