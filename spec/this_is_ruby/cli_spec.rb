# frozen_string_literal: true

require "stringio"

RSpec.describe ThisIsRuby::CLI do
  let(:repo) { build_repo("public/404.html" => RAILS_ERROR_PAGE, "app/models/user.rb" => "class User; end") }
  let(:out) { StringIO.new }
  let(:err) { StringIO.new }

  def run(*argv)
    described_class.call(argv + ["--path", repo.root.to_s, "--no-color"], out:, err:)
  end

  it "writes nothing when only planning" do
    expect(run("plan")).to eq(0)
    expect(repo.root.join(".gitattributes")).not_to exist
    expect(out.string).to include("public/404.html linguist-generated")
  end

  it "writes the file when applying" do
    expect(run("apply")).to eq(0)
    expect(repo.root.join(".gitattributes").read).to include("public/404.html linguist-generated")
  end

  it "defaults to applying" do
    expect(run).to eq(0)
    expect(repo.root.join(".gitattributes")).to exist
  end

  it "fails the check while the file is out of date" do
    expect(run("check")).to eq(1)
    expect(out.string).to include("out of date")
  end

  it "passes the check once the file is written" do
    run("apply")

    expect(run("check")).to eq(0)
  end

  it "refuses to work outside a git repository" do
    status = described_class.call(["--path", Dir.tmpdir, "--no-color"], out:, err:)

    expect(status).to eq(1)
    expect(err.string).to include("not a git repository")
  end

  describe "bad input" do
    # A typo in a CI step has to fail. Exiting 0 here means `check` silently
    # never runs and .gitattributes drifts unnoticed.
    it "fails on an unknown command" do
      expect(run("chekc")).to eq(1)
      expect(err.string).to include("unknown command")
      expect(repo.root.join(".gitattributes")).not_to exist
    end

    it "fails on an unknown option" do
      expect(run("--reticulate")).to eq(1)
      expect(err.string).to include("reticulate")
    end

    it "fails when given more than one command" do
      expect(run("plan", "check")).to eq(1)
      expect(err.string).to include("one command at a time")
    end
  end

  describe "asking for nothing" do
    it "succeeds for --help" do
      expect(run("--help")).to eq(0)
      expect(out.string).to include("Usage: this_is_ruby")
    end

    it "succeeds for --version" do
      expect(run("--version")).to eq(0)
      expect(out.string).to include(ThisIsRuby::VERSION)
    end
  end
end
