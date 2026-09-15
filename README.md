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


By default the gem only points at files a tool produced. On [inertia-rails/react-starter-kit][irsk] that moves TypeScript from 62.3% to 57.5% and leaves it the primary language.

## Make it Ruby

If you think that despite a huge amount of hand-written JS/TS/HTML, the important work in your repository is Ruby, you can say so:

```console
$ this_is_ruby --all-frontend
```
On the same repository that marks `app/javascript/` as `linguist-vendored` and Ruby becomes 84.2%.

The one line that matters is which attribute it uses. [Generated files are suppressed in diffs][docs]; vendored files are not. So `--all-frontend` emits `linguist-vendored`, every source file keeps showing up in full in pull requests, and the only thing that changes is the color of the bar at the top of the page:

```console
$ git check-attr linguist-vendored linguist-generated -- app/javascript/pages/home/index.tsx
app/javascript/pages/home/index.tsx: linguist-vendored: set
app/javascript/pages/home/index.tsx: linguist-generated: unspecified
```

## A note on patterns

Directory rules emit `dir/**`, never `dir/*`. In gitignore syntax, which `.gitattributes` shares, a single star does not cross a slash, so `vendor/*` reaches `vendor/turbo.js` and never `vendor/javascript/turbo.js`. There is a spec that asks `git check-attr` rather than trusting the documentation.

## License

MIT.

[irsk]: https://github.com/inertia-rails/react-starter-kit
[docs]: https://github.com/github-linguist/linguist/blob/main/docs/overrides.md
