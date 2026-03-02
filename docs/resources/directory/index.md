---
title: directory
---

Manage directories on the target system.

## Actions

| Action | Description |
|--------|-------------|
| `:create` | Create the directory (default) |
| `:delete` | Remove the directory |
| `:nothing` | Do nothing (use with notifications) |

## Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `path` | String | Resource name | Path to the directory |
| `mode` | String | -- | Permissions (e.g., `'0755'`) |
| `owner` | String | -- | Directory owner |
| `group` | String | -- | Directory group |

## Examples

### Create a directory

```ruby
directory '/var/www/app' do
  mode '0755'
  owner 'www-data'
  group 'www-data'
end
```

### Create with parent directories

```ruby
directory '/opt/app/shared/config' do
  action :create
end
```

### Delete a directory

```ruby
directory '/tmp/old-cache' do
  action :delete
end
```

### Set ownership

```ruby
directory '/home/deploy/.ssh' do
  mode '0700'
  owner 'deploy'
  group 'deploy'
end
```
