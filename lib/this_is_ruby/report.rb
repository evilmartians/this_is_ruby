# frozen_string_literal: true

module ThisIsRuby
  # Prints what the plan found. Everything here is presentation; decisions
  # were made in Plan.
  class Report
    TOP = 5

    def initialize(plan, out: $stdout, color: out.tty?)
      @plan = plan
      @out = out
      @color = color
    end

    def call
      if @plan.empty? && @plan.redundant.empty?
        say "Nothing to do. Linguist already counts this repository fairly."
        return
      end

      findings
      redundant
      language_bar
    end

    def wrote(path)
      say "", "#{green("Wrote")} #{path}. Commit it: Linguist only reads what is in the repository."
    end

    def drift(path)
      say "", "#{path} is out of date. Run #{bold("this_is_ruby")} and commit the result."
    end

    private

    def findings
      return if @plan.empty?

      say "#{bold(@plan.emissions.sum { |e| e.paths.size })} files Linguist counts that no one in this project wrote:", ""
      @plan.emissions.chunk_while { |a, b| a.rule == b.rule }.each do |group|
        header = group.first.rule.summary
        say "  #{bold(header)}  #{dim("#{human(group.sum { |e| e.bytes(@plan.repo) })}, #{group.sum { |e| e.paths.size }} files")}"
        group.each { |emission| say "    #{emission.line}" }
        say ""
      end
    end

    def redundant
      return if @plan.redundant.empty?

      say dim("Already declared in .gitattributes, left alone:")
      @plan.redundant.each { |emission| say dim("  #{emission.pattern}") }
      say ""
    end

    def language_bar
      before = @plan.before
      after = @plan.after
      return if before.empty?

      say "Estimated language bar #{dim("(GitHub is the authority; this is a guide)")}", ""
      rows = (before.first(TOP).map(&:first) | after.first(TOP).map(&:first))
      width = rows.map(&:length).max
      say "  #{"".ljust(width)}   #{"now".rjust(7)}   #{"after".rjust(7)}"
      rows.each do |language|
        say "  #{language.ljust(width)}   #{share(before, language).rjust(7)}   #{share(after, language).rjust(7)}"
      end
      say ""
      winner = after.first&.first
      say "  Primary language: #{bold(before.first.first)} #{dim("->")} #{green(winner)}" if winner && winner != before.first.first
    end

    def share(totals, language)
      total = totals.sum(&:last)
      return "--" if total.zero?

      bytes = totals.assoc(language)&.last.to_i
      bytes.zero? ? "--" : format("%.1f%%", 100.0 * bytes / total)
    end

    def human(bytes)
      units = ["B", "KB", "MB", "GB"]
      unit = units.shift
      value = bytes.to_f
      while value >= 1024 && units.any?
        value /= 1024
        unit = units.shift
      end
      (unit == "B") ? "#{bytes} B" : format("%.1f %s", value, unit)
    end

    def say(*lines) = lines.each { |line| @out.puts(line) }

    def bold(text) = @color ? "\e[1m#{text}\e[0m" : text

    def dim(text) = @color ? "\e[2m#{text}\e[0m" : text

    def green(text) = @color ? "\e[32m#{text}\e[0m" : text
  end
end
