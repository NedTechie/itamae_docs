# CLAUDE.md — Project Instructions for Claude Code

## Project Overview

Documentation site for **Itamae** (v1.14.2), a lightweight, Chef-inspired configuration management tool for Ruby. Built with Jekyll, hosted on GitHub Pages at https://nedtechie.github.io.

## Tech Stack

- **Site generator:** Jekyll ~3.10 with `pages-themes/cayman@v0.2.0` (remote theme)
- **Markdown:** Kramdown with GFM parser, Rouge syntax highlighting
- **Ruby dependency:** `itamae` ~1.14 (provides resource classes used in tests)
- **Testing:** Minitest ~5.0, Rake
- **Deployment:** GitHub Actions (`.github/workflows/jekyll.yml`) → GitHub Pages

## Commands

```bash
# Install dependencies
bundle install

# Run tests (118 tests, 314 assertions)
bundle exec rake test

# Build site locally
bundle exec jekyll build

# Serve site locally with live reload
bundle exec jekyll serve
```

## Project Structure

```
docs/                          # All documentation pages (each has index.md)
  getting-started/             # Installation & first recipe
  resources/                   # 15 built-in resource pages + overview
  examples/                    # 14 real-world scenario pages + overview
  cli-reference/               # Commands, options, exit codes
  dry-run/                     # Dry-run mode guide
  guides/                      # Hub page linking all guides
  recipes/                     # Recipe DSL guide
  notifications/               # notifies/subscribes
  backends/                    # Local, SSH, Docker, Jail
  node-attributes/             # JSON/YAML node data
  definitions/                 # Reusable resource blocks
  plugins/                     # Recipe & resource plugins
  handlers/                    # Event handlers
  run-command/                 # run_command reference
  best-practices/              # Project structure & patterns
test/
  test_helper.rb               # MockBackend, MockRunner, MockRecipe, ItamaeTestHelpers
  examples/                    # 14 test files mirroring example pages
_layouts/default.html          # Single layout: header, sidebar, content, footer
_includes/sidebar.html         # Navigation with emoji icons (4 sections)
assets/css/style.css           # Custom styles for Cayman theme
_config.yml                    # Jekyll config (permalink: pretty, exclude: test/Rakefile)
```

## Documentation Conventions

- **One page per topic:** Each doc page is `docs/<topic>/index.md` with front matter `title: "emoji Title"`
- **Emoji in titles and headers:** Every page title and `##`/`###` section header starts with an emoji
- **Resource pages** follow a consistent structure: Actions table, Attributes table, How It Works, Dry-Run Behavior, Examples, Inheritance (if applicable)
- **Example pages** include: overview, directory structure, node attributes JSON, full recipe code, ERB templates, run command
- **Cross-references** use Jekyll's `relative_url` filter: `[link text]({{ '/docs/topic/' | relative_url }})`
- **Code blocks** use fenced syntax with language tags (`ruby`, `bash`, `json`, `yaml`, `erb`)

## Testing Conventions

- Tests live in `test/examples/` — one file per example page (e.g., `nginx_test.rb`)
- Each test class includes `ItamaeTestHelpers` and inherits from `Minitest::Test`
- `build_resource(Klass, 'name') { ... }` instantiates resources with mock objects (no backend needed)
- Use `assert_attribute(resource, :attr, value)` for attribute checks
- Use `assert_kind_of` (not `assert_instance_of`) for Hash/Array due to Hashie wrappers (`Itamae::Mash`, `Hashie::Array`)
- Error classes: `Itamae::Resource::InvalidTypeError` (type mismatch), `Itamae::Resource::AttributeMissingError` (required attribute)
- Notifications stored as `Itamae::Notification` structs with `.action` and `.target_resource_desc` fields
- Guards testable via `resource.instance_variable_get(:@only_if_command)` / `@not_if_command`

## Navigation

- **Sidebar** (`_includes/sidebar.html`): 4 sections — Getting Started, Resources, Examples, Advanced
- **Top nav** (`_layouts/default.html`): Home, Getting Started, Resources, CLI Reference, Guides
- When adding a new page, update both `_includes/sidebar.html` and the relevant index page (guides or examples)

## Key Gotchas

- Jekyll excludes `Rakefile` and `test/` (configured in `_config.yml`) — don't remove these exclusions
- Itamae resources only call the backend during `#run`, not `#initialize` — mock testing works because we only test instantiation and attribute DSL
- `Itamae::Node` wraps data in `Hashie::Mash` — symbol/string/method access all work, but type checks need `kind_of?`
- The `service` resource default action is `:nothing` (not `:start`) — this is intentional in Itamae
- `http_request` makes real HTTP calls even in dry-run mode (during `pre_action`) — document this caveat
- Template ERB uses `trim_mode: '-'` — trailing hyphens in ERB tags trim newlines

## Style

- Use emojis in doc page titles and section headers
- Keep recipe examples production-realistic
- Show directory structures for example projects
- Include node attribute JSON alongside recipes
- Always mention dry-run behavior for resource pages
