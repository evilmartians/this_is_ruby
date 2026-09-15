# frozen_string_literal: true

module ThisIsRuby
  # Reads and rewrites .gitattributes, touching only the block it owns.
  #
  # Everything outside the markers is preserved byte for byte: Rails writes
  # its own lines there, and so do people.
  class AttributesFile
    BEGIN_MARKER = "# --- this_is_ruby: begin ---"
    END_MARKER = "# --- this_is_ruby: end ---"
    BLOCK = /^#{Regexp.escape(BEGIN_MARKER)}\n.*?^#{Regexp.escape(END_MARKER)}\n?/m

    PREAMBLE = [
      "# Managed by this_is_ruby. Re-run it when your build setup changes.",
      "# Every path below is counted by GitHub Linguist and written by a tool,",
      "# not by hand. Edit above or below this block, never inside it."
    ].freeze

    attr_reader :path

    def initialize(path)
      @path = Pathname.new(path)
    end

    def current = path.file? ? path.read : ""

    # Patterns already declared outside our block, as pattern => attributes.
    # Rails 8.1 writes the error pages itself; when it has, we say nothing.
    def existing_attributes
      outside = current.sub(BLOCK, "")
      outside.each_line.with_object({}) do |line, acc|
        body = line.split("#", 2).first.to_s.strip
        next if body.empty?

        pattern, *attributes = body.split(/\s+/)
        (acc[pattern] ||= []).concat(attributes)
      end
    end

    def render(emissions)
      # Removing our block must not leave the blank line that separated it.
      outside = current.sub(BLOCK, "").sub(/\n{2,}\z/, "\n")
      return outside if emissions.empty?

      body = +""
      body << BEGIN_MARKER << "\n"
      PREAMBLE.each { |line| body << line << "\n" }
      emissions.chunk_while { |a, b| a.rule == b.rule }.each do |group|
        body << "\n# #{group.first.rule.summary}\n"
        group.each { |emission| body << emission.line << "\n" }
      end
      body << END_MARKER << "\n"

      outside.empty? ? body : "#{outside}\n#{body}"
    end

    def write(emissions)
      contents = render(emissions)
      path.write(contents)
      contents
    end
  end
end
