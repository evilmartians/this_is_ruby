# this_is_ruby

GitHub decides a repository's language by counting bytes. Ruby code can often be outnumbered by sheer volume of JS/TS/HTML boilerplate. So GitHub labels the repo HTML or TypeScript.

This gem gives you controls.

## Install

```ruby
group :development do
  gem "this_is_ruby", require: false
end
```

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


By default the gem only points at files a tool produced. On [inertia-rails/react-starter-kit][irsk], where GitHub counts TypeScript at 60.6%, that clears the HTML but leaves TypeScript the primary language.

## Make it Ruby

If you think that despite a huge amount of hand-written JS/TS/HTML, the important work in your repository is Ruby, you can say so:

```console
$ this_is_ruby --all-frontend
```
On the same repository that marks `app/javascript/` as `linguist-vendored`, and
GitHub then counts it as **82.6% Ruby, 1.1% TypeScript**. That is not an
estimate: [irinanazarova/react-starter-kit-this-is-ruby][demo] is a fork of the
kit whose only change is the sixteen lines this command wrote. Compare its
language bar with [the upstream one][irsk].

The one line that matters is which attribute it uses. [Generated files are suppressed in diffs][docs]; vendored files are not. So `--all-frontend` emits `linguist-vendored`, every source file keeps showing up in full in pull requests, and the only thing that changes is the color of the bar at the top of the page:

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
  alone. That is why `--all-frontend` vendors your frontend rather than
  marking it generated.
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
