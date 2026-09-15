# Changelog

## 0.1.0

Initial release.

- Recognises generated error pages, bundler and asset-pipeline output,
  Webpacker and Vite builds, SimpleCov reports, SQL structure dumps and
  shadcn/ui components.
- Writes a managed block in `.gitattributes`, leaving the rest of the file
  untouched, and stays quiet about anything already declared there.
- `plan`, `apply` and `check` commands; `--all-frontend` opt-in.

## Unreleased

- Exit 1 on an unknown command or option instead of 0, so a typo in a CI step
  fails rather than silently skipping `check`.
- Leave a path alone when its Linguist attribute is already decided, including
  when it was explicitly unset (`-linguist-generated`) or made unspecified
  (`!linguist-generated`). Writing our line after such a declaration reversed
  it, because the last match wins.
- Rewrite the managed block where it already sits, so content below it stays
  below it.
- Read `git rev-parse` from stdout alone: with `GIT_TRACE` set, or on any git
  warning, the merged stream became part of the repository root.
