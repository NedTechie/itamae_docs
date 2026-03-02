---
title: "📖 Writing Recipes"
---

Recipes are Ruby files that describe the desired state of your system using Itamae's resource DSL. Each recipe is executed in order, top to bottom.

## 🏗️ Basic Structure

```ruby
# Install a package
package 'nginx' do
  action :install
end

# Manage a service
service 'nginx' do
  action [:enable, :start]
end

# Create a file
file '/var/www/html/index.html' do
  content '<h1>Hello from Itamae</h1>'
  mode '0644'
  owner 'www-data'
end
```

## 📎 Including Recipes

Include other recipe files using absolute or relative paths:

```ruby
include_recipe '/path/to/recipe.rb'
include_recipe '../cookbooks/nginx/default.rb'
```

When including a directory path, Itamae loads `default.rb` from that directory:

```ruby
include_recipe '../cookbooks/nginx'
# Loads ../cookbooks/nginx/default.rb
```

### 💎 Including from Gems

Include recipes from installed gems (see [Plugins]({{ '/docs/plugins/' | relative_url }})):

```ruby
include_recipe 'nginx'           # loads default.rb from gem
include_recipe 'nginx::ssl'      # loads ssl.rb from gem
```

## 📦 Passing Variables

Pass variables when including recipes:

```ruby
include_recipe 'app' do
  variables(port: 3000, env: 'production')
end
```

## 🔀 Conditional Execution

### 🛡️ Guards

Use `only_if` and `not_if` to conditionally execute resources:

```ruby
execute 'setup database' do
  command '/opt/app/bin/db-setup'
  not_if 'test -f /opt/app/.db-initialized'
end

package 'build-essential' do
  only_if 'which gcc | grep -q "not found"'
end
```

Guards execute shell commands on the target host. A zero exit status means the condition is true.

### ⚡ Multiple Actions

A resource can perform multiple actions:

```ruby
service 'nginx' do
  action [:enable, :start]
end
```

## 📋 Accessing Node Attributes

The `node` object provides access to attributes loaded from JSON/YAML files and host inventory:

```ruby
package node[:database][:package_name]

template '/etc/myapp.conf' do
  variables(
    port: node[:app][:port],
    workers: node[:app][:workers] || 4
  )
end
```

## 🔧 Using `run_command`

Execute commands and capture results within recipes:

```ruby
result = run_command('cat /etc/os-release')
if result.stdout.include?('Ubuntu')
  package 'ubuntu-specific-package'
end
```

The `run_command` method returns a `Specinfra::CommandResult` with:

- `stdout` -- standard output
- `stderr` -- standard error
- `exit_status` -- exit code

It can be used in recipes, definitions, resource blocks, and `local_ruby_block` contexts:

```ruby
local_ruby_block 'conditional setup' do
  block do
    result = run_command('uname -r')
    Itamae.logger.info "Kernel: #{result.stdout.strip}"
  end
end
```

## ✅ Node Validation

Validate node attributes before recipe execution:

```ruby
node.validate! do
  {
    nginx: {
      user: string,
      worker_processes: optional(integer),
      sites: array_of({
        server_name: string,
        root: string,
      }),
    },
  }
end
```

When validation fails, provisioning halts with an error.

## 🔢 Recipe Execution Order

1. Recipes execute top to bottom
2. `include_recipe` inserts the included recipe's resources at that point
3. Delayed notifications run after the entire recipe completes
4. Immediate notifications run right after the notifying resource
