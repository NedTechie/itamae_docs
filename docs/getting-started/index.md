---
title: Getting Started
---

## Installation

Add Itamae to your `Gemfile`:

```ruby
gem 'itamae'
```

Then run:

```bash
bundle install
```

Or install directly:

```bash
gem install itamae
```

## Your First Recipe

Create a file called `recipe.rb`:

```ruby
package 'nginx' do
  action :install
end

service 'nginx' do
  action [:enable, :start]
end
```

## Running Recipes

### Local Execution

Apply the recipe on the local machine:

```bash
itamae local recipe.rb
```

Sample output:

```
 INFO : Starting Itamae...
 INFO : Recipe: /path/to/recipe.rb
 INFO :   package[nginx] installed will change from 'false' to 'true'
 INFO :   service[nginx] enabled will change from 'false' to 'true'
 INFO :   service[nginx] running will change from 'false' to 'true'
```

### Remote Execution via SSH

Apply to a remote host:

```bash
itamae ssh --host host001.example.jp recipe.rb
```

Connect to a Vagrant VM:

```bash
itamae ssh --vagrant --host vm_name recipe.rb
```

### Docker Execution

Build a Docker image with your recipes applied:

```bash
itamae docker --image ubuntu:22.04 --tag myapp:latest recipe.rb
```

## Dry Run

Preview changes without applying them:

```bash
itamae local --dry-run recipe.rb
```

## Node Attributes

Pass host-specific data via JSON or YAML files:

```json
{
  "hostname": "web01",
  "app": {
    "port": 3000
  }
}
```

```bash
itamae local --node-json node.json recipe.rb
```

Access in recipes:

```ruby
execute "hostname #{node[:hostname]}"

template '/etc/app.conf' do
  variables(port: node[:app][:port])
end
```

## Project Scaffolding

Generate a new project:

```bash
itamae init myproject
```

Generate a cookbook:

```bash
itamae generate cookbook nginx
```

Generate a role:

```bash
itamae generate role web
```

## Next Steps

- [Writing Recipes]({{ '/docs/recipes/' | relative_url }}) -- Learn the recipe DSL in depth
- [Resources]({{ '/docs/resources/' | relative_url }}) -- Explore all 15 built-in resources
- [Best Practices]({{ '/docs/best-practices/' | relative_url }}) -- Recommended project structure and patterns
