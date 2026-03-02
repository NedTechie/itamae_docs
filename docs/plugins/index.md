---
title: Plugins
---

Itamae supports two types of plugins distributed as Ruby gems: **recipe plugins** and **resource plugins**.

## Recipe Plugins

Recipe plugins package reusable recipes as gems.

### Naming Convention

Gem name must follow the pattern:

```
itamae-plugin-recipe-<name>
```

Example: `itamae-plugin-recipe-nginx`

### Gem Structure

```
lib/
  itamae/
    plugin/
      recipe/
        nginx/
          default.rb     # loaded by include_recipe 'nginx'
          ssl.rb         # loaded by include_recipe 'nginx::ssl'
        nginx.rb         # fallback if nginx/ directory doesn't exist
```

### Usage

Add the gem to your `Gemfile`:

```ruby
gem 'itamae-plugin-recipe-nginx'
```

Include in your recipe:

```ruby
include_recipe 'nginx'           # loads default.rb
include_recipe 'nginx::ssl'      # loads ssl.rb
```

> Namespaced inclusion (`name::recipe`) requires Itamae v1.5.2+.

## Resource Plugins

Resource plugins add custom resource types.

### Naming Convention

The Ruby class must be:

```ruby
Itamae::Plugin::Resource::FooBar
```

This makes a `foo_bar` resource available in recipes.

### Creating a Resource Plugin

```ruby
# lib/itamae/plugin/resource/foo_bar.rb
module Itamae
  module Plugin
    module Resource
      class FooBar < Itamae::Resource::Base
        define_attribute :action, default: :create
        define_attribute :name, type: String, default_name: true
        define_attribute :option1, type: String

        def set_current_attributes
          # Query current state
        end

        def action_create(options)
          # Implement create action
        end
      end
    end
  end
end
```

### Usage

Once the gem is installed, use the resource in recipes:

```ruby
foo_bar 'my_resource' do
  option1 'value'
  action :create
end
```

### Reference Implementation

Examine the built-in resources in the `lib/itamae/resource/` directory for examples of how to implement custom resources:

- Attribute definition with `define_attribute`
- Current state detection with `set_current_attributes`
- Action methods named `action_<name>`
- Difference reporting for attribute changes

## Finding Plugins

Search for Itamae plugins on [RubyGems.org](https://rubygems.org/search?query=itamae-plugin):

```bash
gem search itamae-plugin
```

## Creating Your Own Plugin

1. Create a new gem:

```bash
bundle gem itamae-plugin-recipe-myapp
```

2. Add Itamae as a dependency in the gemspec:

```ruby
spec.add_dependency 'itamae', '>= 1.14'
```

3. Place recipes in `lib/itamae/plugin/recipe/myapp/` or resources in `lib/itamae/plugin/resource/`.

4. Publish to RubyGems:

```bash
gem build itamae-plugin-recipe-myapp.gemspec
gem push itamae-plugin-recipe-myapp-1.0.0.gem
```
