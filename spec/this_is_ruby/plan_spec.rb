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

  it "stays quiet about what Rails 8.1 already declares" do
    attributes.path.write("public/404.html linguist-generated\n")
    plan = described_class.build(repo, attributes:)

    expect(plan.emissions.map(&:pattern)).to eq(["app/assets/builds/**"])
    expect(plan.redundant.map(&:pattern)).to eq(["public/404.html"])
  end

  it "reports the bar it expects GitHub to show" do
    plan = described_class.build(repo, attributes:)

    expect(plan.before.first.first).to eq("HTML")
    expect(plan.after.first.first).to eq("Ruby")
  end

  it "counts only the bytes it claims" do
    plan = described_class.build(repo, attributes:)

    expect(plan.bytes).to eq(repo.size("public/404.html") + repo.size("app/assets/builds/application.js"))
  end
end
