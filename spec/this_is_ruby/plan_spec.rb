# frozen_string_literal: true

RSpec.describe ThisIsRuby::Plan do
  let(:repo) do
    build_repo(
      "public/404.html" => RAILS_ERROR_PAGE,
      "app/assets/builds/application.js" => "// compiled",
      "app/models/user.rb" => "class User; end"
    )
  end
  let(:attributes) { ThisIsRuby::AttributesFile.new(repo.root.join(".gitattributes")) }

  def plan_with(declaration = nil, **options)
    attributes.path.write(declaration) if declaration
    described_class.build(repo, attributes:, **options)
  end

  describe "what the owner has already decided" do
    it "stays quiet about what Rails 8.1 already declares" do
      plan = plan_with("public/404.html linguist-generated\n")

      expect(plan.emissions.map(&:pattern)).to eq(["app/assets/builds/**"])
      expect(plan.declared.map(&:pattern)).to eq(["public/404.html"])
    end

    # Writing our line after theirs would reverse it, since the last match wins.
    it "honours an attribute the owner explicitly unset" do
      plan = plan_with("public/404.html -linguist-generated\n")

      expect(plan.emissions.map(&:pattern)).to eq(["app/assets/builds/**"])
      expect(plan.declared.map(&:pattern)).to eq(["public/404.html"])
    end

    it "honours an attribute the owner made unspecified" do
      plan = plan_with("public/404.html !linguist-generated\n")

      expect(plan.emissions.map(&:pattern)).to eq(["app/assets/builds/**"])
    end

    it "reads a declaration that reaches the path through a glob" do
      plan = plan_with("public/*.html -linguist-generated\n")

      expect(plan.emissions.map(&:pattern)).to eq(["app/assets/builds/**"])
    end

    it "reads a declaration that reaches the path through a directory" do
      plan = plan_with("app/assets/** linguist-generated\n")

      expect(plan.emissions.map(&:pattern)).to eq(["public/404.html"])
    end

    it "ignores declarations about other attributes entirely" do
      plan = plan_with("public/404.html text eol=lf\n")

      expect(plan.emissions.map(&:pattern)).to include("public/404.html")
      expect(plan.declared).to be_empty
    end
  end

  describe "the language bar" do
    it "ignores our own block, so a second run still shows the contrast" do
      attributes.write(described_class.build(repo, attributes:).emissions)
      plan = described_class.build(repo, attributes:)

      # The block is on disk now, so git reports public/404.html as excluded.
      expect(repo.already_excluded).to include("public/404.html")
      # "now" must still be the bar without it.
      expect(plan.before.first.first).to eq("HTML")
      expect(plan.after.first.first).to eq("Ruby")
    end

    it "honours an exclusion somebody else declared" do
      attributes.path.write("app/models/** linguist-vendored\n")
      plan = described_class.build(repo, attributes:)

      expect(plan.before.map(&:first)).not_to include("Ruby")
    end
  end

  it "reports the bar it expects GitHub to show" do
    plan = plan_with

    expect(plan.before.first.first).to eq("HTML")
    expect(plan.after.first.first).to eq("Ruby")
  end

  it "drops a pattern a broader one already covers" do
    repo = build_repo(
      "components.json" => %({"aliases":{"ui":"@/components/ui"}}),
      "app/javascript/components/ui/button.tsx" => "export const Button = () => null",
      "app/javascript/pages/home.tsx" => "export default function Home() {}"
    )
    attributes = ThisIsRuby::AttributesFile.new(repo.root.join(".gitattributes"))
    plan = described_class.build(repo, attributes:)

    expect(plan.emissions.map(&:pattern)).to eq(["app/javascript/**"])
  end

  it "keeps a narrower pattern when nothing broader covers it" do
    repo = build_repo(
      "components.json" => %({"aliases":{"ui":"@/components/ui"}}),
      "app/javascript/components/ui/button.tsx" => "export const Button = () => null"
    )
    attributes = ThisIsRuby::AttributesFile.new(repo.root.join(".gitattributes"))
    plan = described_class.build(repo, attributes:, frontend: false)

    expect(plan.emissions.map(&:pattern)).to eq(["app/javascript/components/ui/**"])
  end
end
