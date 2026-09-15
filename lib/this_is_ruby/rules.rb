# frozen_string_literal: true

module ThisIsRuby
  # What this gem knows how to recognise.
  #
  # Nothing here duplicates Linguist's own defaults: `node_modules/`,
  # `vendor/`, `.yarn/`, minified JavaScript and lockfiles are already
  # excluded upstream, and repeating them would only make the file longer.
  module Rules
    # Written by `rails new` since Rails 3.0, each naming its own path in a
    # comment. Rails 8.1 ships these lines itself; earlier versions, and any
    # app generated with --skip-git, do not.
    RAILS_ERROR_PAGES = %w[400 404 406-unsupported-browser 422 500].freeze

    # SimpleCov's HTML formatter has opened its report with this title since
    # 0.x. The directory is configurable, so we find it by the marker rather
    # than by assuming `coverage/`.
    SIMPLECOV_MARKER = "<title>Code coverage for"

    # Where a Rails project keeps hand-written frontend sources, in the order
    # the generators have used over the years.
    FRONTEND_ROOTS = %w[app/javascript app/frontend app/webpack frontend].freeze

    module_function

    # Returns the tracked paths under `dir`, or an empty Array.
    def under(repo, dir)
      prefix = "#{dir}/"
      repo.tracked.select { |path| path.start_with?(prefix) }
    end

    # A recursive pattern. `dir/*` would only reach the directory's immediate
    # children. In gitignore syntax, which .gitattributes shares, a single
    # star does not cross a slash.
    def glob(dir) = "#{dir}/**"

    def claim(repo, *dirs)
      dirs.to_h { |dir| [glob(dir), under(repo, dir)] }
    end

    ALL = [
      Rule.new(
        key: :rails_error_pages,
        attribute: "linguist-generated",
        summary: "error pages written by `rails new`"
      ) do |repo|
        RAILS_ERROR_PAGES.filter_map { |page|
          path = "public/#{page}.html"
          next unless repo.tracked?(path)
          # Only the generated page says where it lives. A hand-written 404
          # is the author's own work and stays counted.
          next unless repo.peek(path)&.include?("<!-- This file lives in #{path} -->")

          [path, [path]]
        }.to_h
      end,

      Rule.new(
        key: :bundled_assets,
        attribute: "linguist-generated",
        summary: "bundler output (jsbundling, cssbundling, dartsass, tailwind)"
      ) { |repo| claim(repo, "app/assets/builds") },

      Rule.new(
        key: :precompiled_assets,
        attribute: "linguist-generated",
        summary: "precompiled asset pipeline output"
      ) { |repo| claim(repo, "public/assets") },

      Rule.new(
        key: :webpacker_packs,
        attribute: "linguist-generated",
        summary: "Webpacker/Shakapacker output"
      ) { |repo| claim(repo, "public/packs", "public/packs-test") },

      Rule.new(
        key: :vite_build,
        attribute: "linguist-generated",
        summary: "vite_rails build output"
      ) { |repo| claim(repo, "public/vite", "public/vite-dev", "public/vite-test") },

      Rule.new(
        key: :coverage_report,
        attribute: "linguist-generated",
        summary: "SimpleCov HTML report"
      ) do |repo|
        dirs = repo.tracked.filter_map { |path|
          next unless path.end_with?("/index.html")
          next unless repo.peek(path)&.include?(SIMPLECOV_MARKER)

          File.dirname(path)
        }.uniq
        claim(repo, *dirs)
      end,

      Rule.new(
        key: :sql_schema,
        attribute: "linguist-generated",
        summary: "SQL structure dump (Rails already marks db/schema.rb)"
      ) do |repo|
        path = "db/structure.sql"
        repo.tracked?(path) ? {path => [path]} : {}
      end,

      Rule.new(
        key: :shadcn_components,
        attribute: "linguist-vendored",
        summary: "shadcn/ui components, copied in by its generator"
      ) do |repo|
        # `components.json` is the generator's config; without it these are
        # just ordinary components someone wrote.
        next({}) unless repo.tracked?("components.json")

        dirs = repo.tracked.filter_map { |path|
          dir = File.dirname(path)
          dir if dir.end_with?("components/ui") && path.match?(/\.(tsx|jsx|ts|js|vue|svelte)\z/)
        }.uniq
        claim(repo, *dirs)
      end,

      Rule.new(
        key: :frontend_sources,
        attribute: "linguist-vendored",
        summary: "frontend sources (pass --fair to keep them counted)",
        level: :frontend
      ) do |repo|
        present = FRONTEND_ROOTS.select { |dir| under(repo, dir).any? }
        claim(repo, *present)
      end
    ].freeze

    def for_level(frontend:)
      frontend ? ALL : ALL.select(&:safe?)
    end
  end
end
