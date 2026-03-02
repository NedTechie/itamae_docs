---
title: git
---

Clone and synchronize git repositories on the target system.

## Actions

| Action | Description |
|--------|-------------|
| `:sync` | Clone or update the repository (default) |
| `:nothing` | Do nothing (use with notifications) |

## Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `destination` | String | Resource name | Local path for the repository |
| `repository` | String | **required** | Git repository URL |
| `revision` | String | -- | Branch, tag, or commit SHA |
| `recursive` | Boolean | -- | Clone with `--recursive` (submodules) |
| `depth` | Integer | -- | Shallow clone depth |

## Examples

### Clone a repository

```ruby
git '/opt/app' do
  repository 'https://github.com/user/app.git'
end
```

### Clone a specific branch

```ruby
git '/opt/app' do
  repository 'https://github.com/user/app.git'
  revision 'v2.0'
end
```

### Shallow clone

```ruby
git '/opt/app' do
  repository 'https://github.com/user/app.git'
  depth 1
end
```

### Recursive clone with submodules

```ruby
git '/opt/app' do
  repository 'https://github.com/user/app.git'
  revision 'main'
  recursive true
end
```

### Notify on update

```ruby
git '/opt/app' do
  repository 'https://github.com/user/app.git'
  revision 'main'
  notifies :run, 'execute[bundle install]', :immediately
end

execute 'bundle install' do
  action :nothing
  command 'cd /opt/app && bundle install'
  user 'deploy'
end
```
