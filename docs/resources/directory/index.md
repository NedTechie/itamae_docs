---
title: "📂 directory"
---

# 📂 directory

Manage directories on the target system — create, delete, and set ownership/permissions.

## ⚡ Actions

| Action | Description |
|--------|-------------|
| `:create` | Create the directory **(default)** |
| `:delete` | Remove the directory |
| `:nothing` | Do nothing (use with notifications) |

## 📋 Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `path` | String | Resource name | Path to the directory (auto-set from resource name) |
| `mode` | String | — | Permissions (e.g., `'0755'`) |
| `owner` | String | — | Directory owner |
| `group` | String | — | Directory group |

## 🔍 How It Works

1. **Check existence** — Verifies if the directory exists on the target
2. **Create if missing** — Creates the directory (including parent directories)
3. **Set attributes** — Applies `mode`, `owner`, and `group` if specified
4. **Idempotent** — If the directory exists with the correct attributes, no changes are made

> 💡 Mode strings are normalized to 4 characters with zero-padding (e.g., `'755'` becomes `'0755'`) for consistent comparison.

## 🔬 Dry-Run Behavior

Current mode, owner, and group are queried from the existing directory. You see exactly what permissions would change. No directories are created or removed.

## 📖 Examples

### Create a directory

```ruby
directory '/var/www/app' do
  mode '0755'
  owner 'www-data'
  group 'www-data'
end
```

### Create nested directories

```ruby
%w[releases shared shared/log shared/config].each do |dir|
  directory "/opt/app/#{dir}" do
    owner 'deploy'
    mode '0755'
  end
end
```

### Delete a directory

```ruby
directory '/tmp/old-cache' do
  action :delete
end
```

### Secure directory permissions

```ruby
directory '/home/deploy/.ssh' do
  mode '0700'
  owner 'deploy'
  group 'deploy'
end
```
