---
title: link
---

Create symbolic links on the target system.

## Actions

| Action | Description |
|--------|-------------|
| `:create` | Create the symlink (default) |
| `:nothing` | Do nothing (use with notifications) |

## Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `link` | String | Resource name | Path of the symbolic link |
| `to` | String | **required** | Target path the link points to |
| `force` | Boolean | -- | Force link creation (overwrite existing) |

## Examples

### Create a symlink

```ruby
link '/usr/local/bin/ruby' do
  to '/usr/local/ruby-3.2/bin/ruby'
end
```

### Force overwrite an existing link

```ruby
link '/etc/nginx/sites-enabled/default' do
  to '/etc/nginx/sites-available/myapp'
  force true
end
```

### Link a configuration directory

```ruby
link '/opt/app/current' do
  to '/opt/app/releases/20240101120000'
end
```
