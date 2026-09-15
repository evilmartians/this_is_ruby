# this_is_ruby

[![Gem](https://img.shields.io/gem/v/this_is_ruby)](https://rubygems.org/gems/this_is_ruby)
[![CI](https://github.com/evilmartians/this_is_ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/evilmartians/this_is_ruby/actions/workflows/ci.yml)

Ruby is one of the most eloquent and efficient languages, but it gets punished for it by GitHub's language attribution. A repository's language there is whichever one has the most bytes, and a Rails app, carefully designed to require next to no boilerplate code, easily ends up with less Ruby than JS, TS or HTML (ERB).

This gem tells GitHub: this is Ruby, by marking your frontend as `linguist-vendored`. No side effects on diffs or other DX.

## Install

```ruby
group :development do
  gem "this_is_ruby", require: false
end
```

Or `gem install this_is_ruby` to run it against any repository without adding
it to a project.

## Use

```console
$ this_is_ruby          # write the managed block into .gitattributes
$ this_is_ruby plan     # show what that would write, change nothing
$ this_is_ruby check    # exit 1 when .gitattributes is out of date
```

`check` belongs in CI

## What it recognises

| | attribute |
|---|---|
| error pages from `rails new`, verified by the comment naming their own path | `linguist-generated` |
| `app/assets/builds/` from jsbundling, cssbundling, dartsass, tailwindcss-rails | `linguist-generated` |
| `public/assets/` precompiled asset pipeline output | `linguist-generated` |
| `public/packs/`, `public/packs-test/` from Webpacker and Shakapacker | `linguist-generated` |
| `public/vite*/` from vite_rails | `linguist-generated` |
| SimpleCov HTML reports, found by the report's own title | `linguist-generated` |
| `db/structure.sql`, matching how Rails already treats `db/schema.rb` | `linguist-generated` |
| shadcn/ui components, when `components.json` shows a generator put them there | `linguist-vendored` |
| your frontend sources: `app/javascript/`, `app/frontend/`, `frontend/` | `linguist-vendored` |


[irinanazarova/react-starter-kit-this-is-ruby][demo] is a fork of the Inertia Rails starter kit whose only change is the sixteen lines `this_is_ruby` wrote. Upstream, GitHub counts it as 60.6% TypeScript and 21.2% Ruby. The fork reads **82.6% Ruby, 1.1% TypeScript**. Compare its language bar with [the upstream one][irsk].

## If your frontend really is the point

Some repositories genuinely are TypeScript projects, and for those:

```console
$ this_is_ruby --no-frontend
```

That keeps your frontend in the count and marks only what a tool produced: the
table above minus the last row.

## Why vendored and not generated

The one line that matters is which attribute it uses. [Generated files are suppressed in diffs][docs]; vendored files are not. So your frontend is marked `linguist-vendored`, every source file keeps showing up in full in pull requests, and the only thing that changes is the color of the bar at the top of the page:

```console
$ git check-attr linguist-vendored linguist-generated -- app/javascript/pages/home/index.tsx
app/javascript/pages/home/index.tsx: linguist-vendored: set
app/javascript/pages/home/index.tsx: linguist-generated: unspecified
```

## Side effects

`linguist-*` attributes are a GitHub convention, and plain git does not act on
them. Your local `git diff`, your merges, your CI and every checkout stay
byte-for-byte what they were. Away from GitHub's own pages, nothing changes.

On GitHub itself:

- **`linguist-generated` collapses the file in diffs.** Linguist's docs put it
  plainly: these files "are suppressed in diffs". Reviewers get a "Load diff"
  button instead of the patch. The gem uses this attribute only for tool
  output; everything hand-written gets `linguist-vendored`, which leaves diffs
  alone. That is why your frontend is vendored rather than marked generated.
- **Code search still indexes the files.** They stay findable, and GitHub adds
  `is:generated` and `is:vendored` filters, so a query written as
  `-is:vendored` will skip them.
- **Syntax highlighting is untouched.** Highlighting follows
  `linguist-language=`, which this gem never writes.

Nothing is deleted, moved or rewritten. The files stay in the repository and
in its history, and GitHub only reads `.gitattributes` once you commit it.

## A note on patterns

Directory rules emit `dir/**`, never `dir/*`. In gitignore syntax, which `.gitattributes` shares, a single star does not cross a slash, so `vendor/*` reaches `vendor/turbo.js` and never `vendor/javascript/turbo.js`. There is a spec that asks `git check-attr` rather than trusting the documentation.

## License

MIT.

[irsk]: https://github.com/inertia-rails/react-starter-kit
[docs]: https://github.com/github-linguist/linguist/blob/main/docs/overrides.md
[demo]: https://github.com/irinanazarova/react-starter-kit-this-is-ruby
