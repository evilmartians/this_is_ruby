# frozen_string_literal: true

require "optparse"

module ThisIsRuby
  # Three verbs: write the file, show what would be written, or fail when it
  # has drifted. `check` is the one CI cares about.
  class CLI
    COMMANDS = %w[apply plan check].freeze

    USAGE = <<~TEXT
      Usage: this_is_ruby [command] [options]

      Commands:
        apply     write the managed block into .gitattributes (default)
        plan      show what apply would write, change nothing
        check     exit 1 when .gitattributes is out of date (for CI)

      Options:
    TEXT

    def self.call(argv, out: $stdout, err: $stderr)
      new(argv, out:, err:).call
    end

    def initialize(argv, out: $stdout, err: $stderr)
      @argv = argv
      @out = out
      @err = err
      @options = {path: ".", frontend: true, color: out.tty?}
    end

    def call
      command = parse
      # --help and --version leave nothing to run; bad input leaves nothing to
      # run either, but must not look like success to a CI step.
      return command if command.is_a?(Integer)

      repo = Repo.at(@options[:path])
      attributes = AttributesFile.new(repo.root.join(".gitattributes"))
      plan = Plan.build(repo, attributes:, frontend: @options[:frontend])
      report = Report.new(plan, out: @out, color: @options[:color])

      send(command, plan, attributes, report)
    rescue Repo::NotAGitRepo => error
      @err.puts "this_is_ruby: #{error.message}"
      1
    end

    private

    def apply(plan, attributes, report)
      report.call
      report.wrote(display(attributes.path)) if attributes.write(plan.emissions)
      0
    end

    def plan(plan, attributes, report)
      report.call
      0
    end

    def check(plan, attributes, report)
      return 0 unless attributes.stale?(plan.emissions)

      report.call
      report.drift(display(attributes.path))
      1
    end

    def display(path)
      path.relative_path_from(Pathname.pwd).to_s
    rescue ArgumentError
      path.to_s
    end

    def parse
      parser = OptionParser.new do |opts|
        opts.banner = USAGE
        opts.on("--path DIR", "repository to inspect (default: .)") { |dir| @options[:path] = dir }
        opts.on("--[no-]frontend", "mark hand-written frontend sources as vendored (default: yes)") { |on| @options[:frontend] = on }
        # 0.1.x asked for this behaviour with a flag. It is the default now, so
        # accept the old name rather than break anyone's CI step.
        opts.on("--all-frontend", "deprecated alias, now the default") { @options[:frontend] = true }
        opts.on("--[no-]color", "colourise output") { |on| @options[:color] = on }
        opts.on("-v", "--version", "print the version") do
          @out.puts VERSION
          return 0
        end
        opts.on("-h", "--help", "print this message") do
          @out.puts opts
          return 0
        end
      end
      rest = parser.parse(@argv)
      return refuse(parser, "one command at a time, got #{rest.join(" ")}") if rest.size > 1

      command = rest.first || "apply"
      return refuse(parser, "unknown command #{command.inspect}") unless COMMANDS.include?(command)

      command
    rescue OptionParser::ParseError => error
      refuse(parser, error.message)
    end

    # Returns the exit status, so a typo in a CI step fails instead of passing.
    def refuse(parser, message)
      @err.puts "this_is_ruby: #{message}"
      @err.puts parser
      1
    end
  end
end
