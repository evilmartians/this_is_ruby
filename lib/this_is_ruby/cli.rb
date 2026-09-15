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
      @options = {path: ".", all_frontend: false, color: out.tty?}
    end

    def call
      command = parse
      return 0 unless command

      repo = Repo.at(@options[:path])
      attributes = AttributesFile.new(repo.root.join(".gitattributes"))
      plan = Plan.build(repo, attributes:, all_frontend: @options[:all_frontend])
      report = Report.new(plan, out: @out, color: @options[:color])

      send(command, plan, attributes, report)
    rescue Repo::NotAGitRepo => error
      @err.puts "this_is_ruby: #{error.message}"
      1
    end

    private

    def apply(plan, attributes, report)
      report.call
      before = attributes.current
      after = attributes.render(plan.emissions)
      return 0 if before == after

      attributes.path.write(after)
      report.wrote(display(attributes.path))
      0
    end

    def plan(plan, attributes, report)
      report.call
      0
    end

    def check(plan, attributes, report)
      return 0 if attributes.current == attributes.render(plan.emissions)

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
        opts.on("--all-frontend", "also mark hand-written frontend sources as vendored") { @options[:all_frontend] = true }
        opts.on("--[no-]color", "colourise output") { |on| @options[:color] = on }
        opts.on("-v", "--version", "print the version") {
          @out.puts VERSION
          return nil
        }
        opts.on("-h", "--help", "print this message") {
          @out.puts opts
          return nil
        }
      end
      rest = parser.parse(@argv)
      command = rest.first || "apply"
      raise OptionParser::InvalidArgument, command unless COMMANDS.include?(command)

      command
    rescue OptionParser::ParseError => error
      @err.puts "this_is_ruby: #{error.message}"
      @err.puts parser
      nil
    end
  end
end
