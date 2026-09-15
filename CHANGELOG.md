# Changelog

## 0.2.1

- The managed block is now just the patterns between its two markers, down from
  16 lines to 8. The preamble was the block explaining itself on top of a marker
  that already names the gem, and the per-group comments repeated what the
  report says at more length. `check` reports the file as out of date once after
  upgrading; re-running writes the shorter block.

## 0.2.0

- Frontend sources are vendored by default. Telling GitHub a project is Ruby is
  what the gem is for, and it read oddly to name that after a flag most people
  would never pass. `--fair` keeps them counted, marking only what a tool wrote
  or a generator copied in, for a repository whose frontend really is the point. `--all-frontend` is still accepted and does
  nothing, so an existing CI step keeps working.
- Reword the summary and description.

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
