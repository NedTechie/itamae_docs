---
title: "📦 package"
---

# 📦 package

Install, remove, or manage system packages using the OS package manager (apt, yum, dnf, etc.).

## ⚡ Actions

| Action | Description |
|--------|-------------|
| `:install` | Install the package **(default)** |
| `:remove` | Remove the package |
| `:nothing` | Do nothing (use with notifications) |

## 📋 Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | String | Resource name | Package name (auto-set from resource name) |
| `version` | String | — | Specific version to install |
| `options` | String | — | Additional package manager options |

> 💡 The `name` attribute uses **`default_name`** — it automatically takes the value you pass as the resource name (e.g., `package 'nginx'` sets `name` to `"nginx"`).

## 🔍 How It Works

1. **Query** — Checks if the package is installed via the system package manager
2. **Compare** — If `version` is specified, compares against the currently installed version
3. **Install/Remove** — Runs the appropriate package manager command
4. **Idempotent** — Won't reinstall if already at the desired version

## 🔬 Dry-Run Behavior

In [dry-run mode]({{ '/docs/dry-run/' | relative_url }}), the current package state is fully queried. You see exactly which packages would be installed or removed, and version changes. No packages are actually installed or removed.

## 📖 Examples

### Install a package

```ruby
package 'nginx'
```

### Install with a specific version

```ruby
package 'sl' do
  version '3.03-17'
end
```

### Install multiple packages

```ruby
%w[git curl wget vim].each do |pkg|
  package pkg
end
```

### Install with options

```ruby
package 'nginx' do
  options '--force-yes'
end
```

### Remove a package

```ruby
package 'apache2' do
  action :remove
end
```

### Notify a service on install

```ruby
package 'nginx' do
  notifies :restart, 'service[nginx]'
end
```
