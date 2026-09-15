# Changelog

## 0.1.0

Initial release.

- Recognises generated error pages, bundler and asset-pipeline output,
  Webpacker and Vite builds, SimpleCov reports, SQL structure dumps and
  shadcn/ui components.
- Writes a managed block in `.gitattributes`, leaving the rest of the file
  untouched, and stays quiet about anything already declared there.
- `plan`, `apply` and `check` commands; `--all-frontend` opt-in.
