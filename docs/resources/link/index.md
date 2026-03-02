---
title: "🔗 link"
---

# 🔗 link

Create symbolic links on the target system.

## ⚡ Actions

| Action | Description |
|--------|-------------|
| `:create` | Create the symlink **(default)** |
| `:nothing` | Do nothing (use with notifications) |

## 📋 Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `link` | String | Resource name | Path of the symbolic link (auto-set from resource name) |
| `to` | String | **required** ⚠️ | Target path the link points to |
| `force` | Boolean | `false` | Force link creation — overwrite existing files/links |

> 💡 When `force` is `true`, both the `force` and `no_dereference` flags are passed to the underlying command, allowing you to overwrite existing symlinks or files.

## 🔍 How It Works

1. **Check existence** — Checks if the link already exists
2. **Check target** — If the link exists, reads its current target
3. **Create/Update** — Only creates or updates the link if it doesn't point to the correct target
4. **Idempotent** — If the link already points to the correct target, no changes are made

## 🔬 Dry-Run Behavior

The current symlink target is read from the system. You see whether the link would be created or updated with the new target path.

## 📖 Examples

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

### Link a release directory (deploy pattern)

```ruby
link '/opt/app/current' do
  to '/opt/app/releases/20240101120000'
end
```

### Notify on link change 🔔

```ruby
link '/etc/nginx/sites-enabled/app.conf' do
  to '/etc/nginx/sites-available/app.conf'
  notifies :reload, 'service[nginx]'
end
```
