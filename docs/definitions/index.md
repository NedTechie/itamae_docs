---
title: Definitions
---

Definitions let you group multiple resources into a reusable, parameterized block -- similar to a lightweight custom resource.

## Defining a Definition

Use the `define` keyword at the top level of a recipe:

```ruby
define :install_and_enable_package, version: nil do
  v = params[:version]

  package params[:name] do
    version v if v
    action :install
  end

  service params[:name] do
    action :enable
  end
end
```

Parameters:
- First argument: the definition name (as a Symbol)
- Keyword arguments: parameter names with default values
- Block: the resource declarations

Inside the block, `params` is a hash containing:
- `:name` -- the resource name passed when using the definition
- Any keyword parameters you declared

## Using a Definition

Once defined, use it like any other resource:

```ruby
install_and_enable_package 'nginx' do
  version '1.6.1'
end

install_and_enable_package 'redis'
```

> A `define` must appear **before** it is used in the recipe. Define it at the top of the file or in an included recipe.

## Practical Examples

### Application deployment pattern

```ruby
define :deploy_app, user: 'deploy', port: 3000 do
  directory "/opt/#{params[:name]}" do
    owner params[:user]
  end

  git "/opt/#{params[:name]}" do
    repository "https://github.com/org/#{params[:name]}.git"
    revision 'main'
  end

  template "/etc/systemd/system/#{params[:name]}.service" do
    source 'app.service.erb'
    variables(
      name: params[:name],
      user: params[:user],
      port: params[:port]
    )
    notifies :run, "execute[systemctl daemon-reload]"
  end
end

execute 'systemctl daemon-reload' do
  action :nothing
end

deploy_app 'web-api' do
  port 4000
end

deploy_app 'worker'
```

### Conditional package installation

```ruby
define :install_if_missing do
  execute "install #{params[:name]}" do
    command "apt-get install -y #{params[:name]}"
    not_if "dpkg -l #{params[:name]} | grep -q ^ii"
  end
end

install_if_missing 'htop'
install_if_missing 'jq'
```

## Definitions vs. Resource Plugins

| Feature | Definitions | Resource Plugins |
|---------|-------------|-----------------|
| Complexity | Simple | More involved |
| Distribution | Inline in recipes | Gem-based |
| Reuse scope | Within the project | Across projects |
| Custom logic | Limited | Full Ruby class |

Use definitions for project-specific abstractions. Use [resource plugins]({{ '/docs/plugins/' | relative_url }}) when you need to share resources across projects.
