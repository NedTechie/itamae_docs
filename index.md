---
title: Home
sidebar: true
---

Itamae is a lightweight, Chef-inspired configuration management tool written in Ruby. It lets you define your infrastructure as code using a simple, readable DSL and apply it to local or remote machines.

## Why Itamae?

- **Simple** -- Minimal DSL with a gentle learning curve. If you know Chef, you already know Itamae.
- **Lightweight** -- No server, no agent. Just a gem and your recipes.
- **Flexible** -- Run locally, over SSH, inside Docker containers, or in FreeBSD jails.
- **Extensible** -- Plugin system for custom resources and recipes distributed as gems.

## Quick Example

```ruby
# recipe.rb
package 'nginx' do
  action :install
end

service 'nginx' do
  action [:enable, :start]
end

template '/etc/nginx/nginx.conf' do
  source 'nginx.conf.erb'
  variables(worker_processes: 4)
  notifies :restart, 'service[nginx]'
end
```

```bash
# Apply locally
itamae local recipe.rb

# Apply via SSH
itamae ssh --host web01.example.com recipe.rb

# Apply to Vagrant VM
itamae ssh --vagrant --host default recipe.rb
```

## Installation

Add to your `Gemfile`:

```ruby
gem 'itamae', '~> 1.14', '>= 1.14.2'
```

Or install directly:

```bash
gem install itamae
```

## Documentation

| Section | Description |
|---------|-------------|
| [Getting Started](docs/getting-started/) | Installation, first recipe, running Itamae |
| [Resources](docs/resources/) | All 15 built-in resource types |
| [CLI Reference](docs/cli-reference/) | Commands, options, and exit codes |
| [Backends](docs/backends/) | Local, SSH, Docker, and Jail backends |
| [Guides](docs/guides/) | Recipes, definitions, notifications, and more |
