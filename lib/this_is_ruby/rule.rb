# frozen_string_literal: true

module ThisIsRuby
  # One family of files that Linguist counts but nobody in the project wrote.
  #
  # A rule is handed the repo and returns a Hash of pattern => tracked paths.
  # Rules never guess: when the evidence is not on disk they return nothing,
  # so a project that has no coverage report gets no line about one.
  #
  # :safe rules find files a tool produced. :frontend rules find hand-written
  # sources, which is a claim about what the repository is rather than about
  # who typed the file; both run by default, and --no-frontend drops the
  # second group for a project whose frontend really is the point.
  class Rule
    LEVELS = %i[safe frontend].freeze

    attr_reader :key, :attribute, :summary, :level

    def initialize(key:, attribute:, summary:, level: :safe, &finder)
      raise ArgumentError, "unknown level #{level.inspect}" unless LEVELS.include?(level)
      raise ArgumentError, "rule #{key} needs a finder" unless finder

      @key = key
      @attribute = attribute
      @summary = summary
      @level = level
      @finder = finder
    end

    def safe? = level == :safe

    # Returns an Array of Emission, empty when this repo has nothing to claim.
    def apply(repo)
      found = @finder.call(repo) || {}
      found.filter_map do |pattern, paths|
        next if paths.nil? || paths.empty?

        Emission.new(pattern:, attribute:, paths: paths.sort.freeze, rule: self)
      end
    end
  end
end
