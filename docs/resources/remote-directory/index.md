---
title: remote_directory
---

Upload an entire directory from the local machine to the target system.

## Actions

| Action | Description |
|--------|-------------|
| `:create` | Upload the directory (default) |
| `:delete` | Remove the directory |
| `:nothing` | Do nothing (use with notifications) |

## Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `path` | String | Resource name | Destination path on the target |
| `source` | String | **required** | Source directory (relative to recipe) |
| `mode` | String | -- | Directory permissions |
| `owner` | String | -- | Directory owner |
| `group` | String | -- | Directory group |

## Examples

### Upload a configuration directory

```ruby
remote_directory '/etc/app/config' do
  source 'files/config'
  mode '0755'
  owner 'app'
  group 'app'
end
```

### Upload static assets

```ruby
remote_directory '/var/www/static' do
  source 'files/static'
  mode '0755'
  owner 'www-data'
end
```
