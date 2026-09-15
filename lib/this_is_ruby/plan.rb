# frozen_string_literal: true

module ThisIsRuby
  # What we intend to write, and what we deliberately left alone.
  class Plan
    LINGUIST_ATTRIBUTES = %w[linguist-generated linguist-vendored linguist-documentation].freeze

    attr_reader :repo, :emissions, :declared

    def self.build(repo, attributes:, all_frontend: false)
      spoken_for = spoken_for(attributes.existing_attributes)
      found = Rules.for_level(all_frontend:).flat_map { |rule| rule.apply(repo) }
      declared, emissions = found.partition do |emission|
        spoken_for.any? { |pattern| covers?(pattern, emission.pattern) }
      end
      new(repo:, emissions: prune(emissions), declared:)
    end

    # Patterns whose Linguist attributes the owner has already decided, set or
    # unset. `-linguist-generated` is a decision too, and writing our own line
    # after it would quietly reverse it, since the last match wins.
    def self.spoken_for(existing)
      existing.filter_map do |pattern, attributes|
        names = attributes.map { |attribute| attribute.delete_prefix("-").delete_prefix("!").split("=").first }
        pattern if (names & LINGUIST_ATTRIBUTES).any?
      end
    end

    # Does a declared pattern speak for the one we were about to write?
    #
    # Only the two shapes we emit are resolved: `dir/**` reaches everything
    # below it, and anything else matches the way a single star does in
    # gitignore syntax. A declared pattern covering only some of an emission's
    # paths is not detected.
    def self.covers?(declared, pattern)
      return true if declared == pattern
      return pattern.start_with?(declared.delete_suffix("**")) if declared.end_with?("**")

      File.fnmatch?(declared, pattern, File::FNM_PATHNAME)
    end

    # Drops a pattern when a broader one already carries the same attribute:
    # once `app/javascript/**` is vendored, saying so again about
    # `app/javascript/components/ui/**` only makes the file longer.
    def self.prune(emissions)
      emissions.reject do |emission|
        emissions.any? do |other|
          next false unless other.pattern.end_with?("**")
          next false if other.pattern == emission.pattern || other.attribute != emission.attribute

          emission.pattern.start_with?(other.pattern.delete_suffix("**"))
        end
      end
    end

    def initialize(repo:, emissions:, declared:)
      @repo = repo
      @emissions = emissions.freeze
      @declared = declared.freeze
    end

    def empty? = emissions.empty?

    def claimed_paths
      @claimed_paths ||= emissions.flat_map(&:paths).to_set
    end

    def before = @before ||= LanguageEstimate.of(repo)

    def after = @after ||= LanguageEstimate.of(repo, excluding: claimed_paths)
  end
end
