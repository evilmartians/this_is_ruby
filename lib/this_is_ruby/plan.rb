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
      new(repo:, emissions:, redundant:)
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
