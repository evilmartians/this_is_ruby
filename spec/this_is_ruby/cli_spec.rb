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

  it "rejects an unknown command" do
    expect(run("yolo")).to eq(0).or eq(1)
    expect(err.string).to include("yolo")
  end
end
