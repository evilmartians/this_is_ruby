# frozen_string_literal: true

RSpec.describe ThisIsRuby::Repo do
  describe "#already_excluded" do
    it "asks git, so every pattern shape resolves the way git resolves it" do
      repo = build_repo(
        ".gitattributes" => "deep/** linguist-vendored\ndb/schema.rb linguist-generated\n",
        "deep/nested/far/away.tsx" => "//",
        "db/schema.rb" => "# schema",
        "app/models/user.rb" => "class User; end"
      )

      expect(repo.already_excluded).to contain_exactly("deep/nested/far/away.tsx", "db/schema.rb")
    end

    it "is empty when nothing is declared" do
      expect(build_repo("app/models/user.rb" => "class User; end").already_excluded).to be_empty
    end
  end
end

RSpec.describe ThisIsRuby::Rules do
  def patterns_for(repo, frontend: true)
    described_class.for_level(frontend:)
      .flat_map { |rule| rule.apply(repo) }
      .map(&:line)
  end

  describe "generated Rails error pages" do
    it "claims a page that says where it lives" do
      repo = build_repo("public/404.html" => RAILS_ERROR_PAGE, "Gemfile" => "")

      expect(patterns_for(repo)).to include("public/404.html linguist-generated")
    end

    it "leaves a hand-written error page alone" do
      repo = build_repo("public/404.html" => "<h1>Gone fishing</h1>", "Gemfile" => "")

      expect(patterns_for(repo)).to be_empty
    end

    it "only looks at the five pages the generator writes" do
      repo = build_repo("public/418.html" => RAILS_ERROR_PAGE.sub("404", "418"), "Gemfile" => "")

      expect(patterns_for(repo)).to be_empty
    end
  end

  describe "build output" do
    it "claims bundler and asset pipeline directories" do
      repo = build_repo(
        "app/assets/builds/application.js" => "// compiled",
        "public/assets/application-abc123.css" => "body{}",
        "public/packs/js/runtime.js" => "// webpack",
        "public/vite/assets/index.js" => "// vite"
      )

      expect(patterns_for(repo)).to contain_exactly(
        "app/assets/builds/** linguist-generated",
        "public/assets/** linguist-generated",
        "public/packs/** linguist-generated",
        "public/vite/** linguist-generated"
      )
    end

    it "says nothing about directories that are not there" do
      repo = build_repo("app/models/user.rb" => "class User; end")

      expect(patterns_for(repo)).to be_empty
    end
  end

  describe "SimpleCov reports" do
    it "finds the report by its title, wherever it was written" do
      repo = build_repo(
        "spec/coverage/index.html" => SIMPLECOV_INDEX,
        "spec/coverage/assets/0.22.0/application.js" => "// simplecov"
      )

      expect(patterns_for(repo)).to eq(["spec/coverage/** linguist-generated"])
    end

    it "ignores an ordinary index.html" do
      repo = build_repo("docs/index.html" => "<h1>Docs</h1>")

      expect(patterns_for(repo)).to be_empty
    end
  end

  describe "shadcn/ui components" do
    let(:files) do
      {
        "components.json" => %({"aliases":{"ui":"@/components/ui"}}),
        "app/javascript/components/ui/button.tsx" => "export const Button = () => null",
        "app/javascript/pages/home.tsx" => "export default function Home() {}"
      }
    end

    # With the frontend rule on, `app/javascript/**` covers these anyway. These
    # examples pin the shadcn rule itself, which is what --no-frontend leaves.
    it "vendors the generator's directory and nothing else" do
      expect(patterns_for(build_repo(files), frontend: false))
        .to eq(["app/javascript/components/ui/** linguist-vendored"])
    end

    it "claims nothing without the generator's config" do
      expect(patterns_for(build_repo(files.except("components.json")), frontend: false)).to be_empty
    end
  end

  describe "frontend sources" do
    it "are vendored by default, and kept by --no-frontend" do
      repo = build_repo("app/javascript/pages/home.tsx" => "export default function Home() {}")

      expect(patterns_for(repo)).to eq(["app/javascript/** linguist-vendored"])
      expect(patterns_for(repo, frontend: false)).to be_empty
    end

    it "vendors rather than generates, so diffs keep working" do
      frontend = described_class::ALL.reject(&:safe?)

      expect(frontend.map(&:attribute).uniq).to eq(["linguist-vendored"])
    end
  end

  it "never repeats what Linguist already excludes" do
    repo = build_repo(
      "node_modules/react/index.js" => "// react",
      "vendor/javascript/turbo.js" => "// turbo"
    )

    expect(patterns_for(repo)).to be_empty
  end
end
