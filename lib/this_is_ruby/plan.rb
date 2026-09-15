# frozen_string_literal: true

module ThisIsRuby
  # What we intend to write, and what we deliberately left alone.
  class Plan
    LINGUIST_ATTRIBUTES = %w[linguist-generated linguist-vendored linguist-documentation].freeze
    EMPTY = [].freeze

    attr_reader :repo, :emissions, :redundant

    def self.build(repo, attributes:, all_frontend: false)
      declared = attributes.existing_attributes
      found = Rules.for_level(all_frontend:).flat_map { |rule| rule.apply(repo) }
      redundant, emissions = found.partition do |emission|
        (declared.fetch(emission.pattern, EMPTY) & LINGUIST_ATTRIBUTES).any?
      end
      new(repo:, emissions: prune(emissions), redundant:)
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

    def initialize(repo:, emissions:, redundant:)
      @repo = repo
      @emissions = emissions.freeze
      @redundant = redundant.freeze
    end

    def empty? = emissions.empty?

    def claimed_paths
      @claimed_paths ||= emissions.flat_map(&:paths).to_set
    end

    def bytes = emissions.sum { |emission| emission.bytes(repo) }

    def before = LanguageEstimate.of(repo)

    def after = LanguageEstimate.of(repo, excluding: claimed_paths)
  end
end
