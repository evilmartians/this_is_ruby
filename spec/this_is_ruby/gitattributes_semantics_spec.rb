# frozen_string_literal: true

# The whole gem rests on git applying the patterns we emit. `dir/*` reaches
# only a directory's immediate children, because in gitignore syntax, which
# .gitattributes shares, a single star does not cross a slash. So every
# directory rule emits `dir/**`. This asks git rather than trusting the docs.
RSpec.describe "gitattributes glob semantics" do
  let(:repo) do
    build_repo(
      "deep/top.tsx" => "//",
      "deep/nested/far/away.tsx" => "//"
    )
  end

  def attribute_on(path, pattern:)
    repo.root.join(".gitattributes").write("#{pattern} linguist-vendored\n")
    out = `git -C #{repo.root} check-attr linguist-vendored -- #{path}`
    out.split(": ").last.strip
  end

  it "reaches nested files with a double star" do
    expect(attribute_on("deep/nested/far/away.tsx", pattern: "deep/**")).to eq("set")
  end

  it "does not reach them with a single star" do
    expect(attribute_on("deep/nested/far/away.tsx", pattern: "deep/*")).to eq("unspecified")
    expect(attribute_on("deep/top.tsx", pattern: "deep/*")).to eq("set")
  end

  it "applies every pattern the rules emit" do
    repo = build_repo(
      "public/404.html" => RAILS_ERROR_PAGE,
      "app/assets/builds/nested/application.js" => "// compiled"
    )
    emissions = ThisIsRuby::Rules::ALL.flat_map { |rule| rule.apply(repo) }
    ThisIsRuby::AttributesFile.new(repo.root.join(".gitattributes")).write(emissions)

    emissions.flat_map(&:paths).each do |path|
      out = `git -C #{repo.root} check-attr #{emissions.first.attribute} -- #{path}`
      expect(out).to match(/: set$/), "#{path} was not covered by the emitted pattern"
    end
  end
end
