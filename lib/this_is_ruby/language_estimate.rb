# frozen_string_literal: true

module ThisIsRuby
  # A rough stand-in for GitHub's language bar.
  #
  # Linguist is far more careful than this: it sniffs content, resolves
  # ambiguous extensions and applies heuristics we do not reimplement. The
  # point here is only to show which way the bar moves, so the numbers are
  # always presented as an estimate and GitHub stays the authority.
  module LanguageEstimate
    # Only types Linguist counts: programming and markup. Anything absent
    # here (JSON, YAML, Markdown, lockfiles) is data or prose and scores
    # nothing, which is why package-lock.json never mattered.
    EXTENSIONS = {
      ".rb" => "Ruby", ".rake" => "Ruby", ".gemspec" => "Ruby", ".ru" => "Ruby",
      ".erb" => "HTML", ".html" => "HTML", ".htm" => "HTML",
      ".haml" => "Haml", ".slim" => "Slim",
      ".ts" => "TypeScript", ".tsx" => "TypeScript", ".mts" => "TypeScript",
      ".js" => "JavaScript", ".jsx" => "JavaScript", ".mjs" => "JavaScript",
      ".css" => "CSS", ".scss" => "SCSS", ".sass" => "SCSS", ".less" => "Less",
      ".vue" => "Vue", ".svelte" => "Svelte",
      ".py" => "Python", ".go" => "Go", ".rs" => "Rust", ".java" => "Java",
      ".sh" => "Shell", ".bash" => "Shell", ".sql" => "SQL", ".ejs" => "EJS"
    }.freeze

    FILENAMES = {
      "Gemfile" => "Ruby", "Rakefile" => "Ruby", "Guardfile" => "Ruby",
      "Capfile" => "Ruby", "Dockerfile" => "Dockerfile"
    }.freeze

    # The parts of Linguist's own vendor list a Ruby project actually hits.
    # Mirrored here so the estimate does not count bytes GitHub never counts.
    VENDORED = Regexp.union(
      %r{(\A|/)node_modules/},
      %r{(\A|/)bower_components/},
      %r{(\A|/)\.yarn/(releases|plugins|sdks|versions|unplugged)/},
      %r{(\A|/)vendors?/},
      /\.min\.(js|css)\z/
    )

    module_function

    # Returns [[language, bytes], ...], largest first.
    def of(repo, excluding: Set.new)
      totals = Hash.new(0)
      repo.tracked.each do |path|
        next if excluding.include?(path) || VENDORED.match?(path)

        language = language_for(path)
        totals[language] += repo.size(path) if language
      end
      totals.sort_by { |language, bytes| [-bytes, language] }
    end

    def language_for(path)
      name = File.basename(path)
      return FILENAMES[name] if FILENAMES.key?(name)

      # `index.html.erb` is ERB templating HTML; GitHub reports it as HTML.
      EXTENSIONS[File.extname(name).downcase]
    end
  end
end
