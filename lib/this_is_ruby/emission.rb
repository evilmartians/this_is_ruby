# frozen_string_literal: true

module ThisIsRuby
  # One line destined for .gitattributes, plus the tracked paths that earned
  # it. The paths are what the report shows and what the language estimate
  # subtracts; the pattern is all that reaches the file.
  Emission = Data.define(:pattern, :attribute, :paths, :rule) do
    def line
      "#{pattern} #{attribute}"
    end

    def bytes(repo)
      paths.sum { |path| repo.size(path) }
    end
  end
end
