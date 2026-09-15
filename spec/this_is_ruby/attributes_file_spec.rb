# frozen_string_literal: true

RSpec.describe ThisIsRuby::AttributesFile do
  subject(:attributes) { described_class.new(repo.root.join(".gitattributes")) }

  let(:repo) { build_repo("public/404.html" => RAILS_ERROR_PAGE) }
  let(:emissions) { ThisIsRuby::Rules::ALL.flat_map { |rule| rule.apply(repo) } }

  it "writes a block that git can act on" do
    attributes.write(emissions)

    expect(attributes.current).to include("public/404.html linguist-generated")
    expect(attributes.current).to start_with(described_class::BEGIN_MARKER)
    expect(attributes.current).to end_with("#{described_class::END_MARKER}\n")
  end

  it "produces the same file every time" do
    attributes.write(emissions)
    first = attributes.current

    expect(attributes.write(emissions)).to be(false)
    expect(attributes.current).to eq(first)
  end

  it "rewrites the block where it sits, leaving what is below it below" do
    attributes.path.write("*.rb text\n")
    attributes.write(emissions)
    attributes.path.write("#{attributes.current}\n*.md linguist-documentation\n")
    attributes.write(emissions)

    lines = attributes.current.lines.map(&:chomp)
    expect(lines.first).to eq("*.rb text")
    expect(lines.last).to eq("*.md linguist-documentation")
    expect(lines.index(described_class::END_MARKER)).to be < lines.index("*.md linguist-documentation")
  end

  it "settles after one run even with content on both sides" do
    attributes.path.write("*.rb text\n")
    attributes.write(emissions)
    attributes.path.write("#{attributes.current}\n*.md linguist-documentation\n")
    attributes.write(emissions)
    settled = attributes.current

    expect(attributes.write(emissions)).to be(false)
    expect(attributes.current).to eq(settled)
  end

  it "keeps what Rails and people wrote around it" do
    attributes.path.write("vendor/* linguist-vendored\n")
    attributes.write(emissions)

    expect(attributes.current).to start_with("vendor/* linguist-vendored\n")
    expect(attributes.current.scan("vendor/*").size).to eq(1)
  end

  it "drops its own block when there is nothing left to say" do
    attributes.path.write("*.rb text\n")
    attributes.write(emissions)
    attributes.write([])

    expect(attributes.current).to eq("*.rb text\n")
  end

  describe "#stale?" do
    it "is true until the block is written, false after" do
      expect(attributes.stale?(emissions)).to be(true)
      attributes.write(emissions)
      expect(attributes.stale?(emissions)).to be(false)
    end
  end

  describe "#existing_attributes" do
    it "reads declarations made outside the block" do
      attributes.path.write(<<~TEXT)
        # a comment
        db/schema.rb linguist-generated
        public/404.html linguist-generated  # trailing note
      TEXT

      expect(attributes.existing_attributes).to eq(
        "db/schema.rb" => ["linguist-generated"],
        "public/404.html" => ["linguist-generated"]
      )
    end

    it "does not count its own block as someone else's declaration" do
      attributes.write(emissions)

      expect(attributes.existing_attributes).to be_empty
    end
  end
end
