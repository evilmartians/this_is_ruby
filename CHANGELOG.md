# Changelog

## 0.1.1

- The "now" column no longer counts files that are already out of GitHub's
  language bar. It asks `git check-attr`, so Rails' own `db/schema.rb` line and
  anything written by hand are honoured, and it subtracts only what this run
  claims, so re-running on a repository already converted still shows the
  contrast rather than reporting that nothing would change.

## 0.1.0

Initial release.

- Recognises generated error pages, bundler and asset-pipeline output,
  Webpacker and Vite builds, SimpleCov reports, SQL structure dumps and
  shadcn/ui components.
- Writes a managed block in `.gitattributes`, leaving the rest of the file
  untouched, and stays quiet about anything already decided there, including an
  attribute the owner explicitly unset.
- Rewrites the block where it sits, so content below it stays below it.
- `plan`, `apply` and `check` commands; `--all-frontend` opt-in, which uses
  `linguist-vendored` so diffs keep working.
