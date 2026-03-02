---
title: "💎 gem_package"
---

# 💎 gem_package

Install, uninstall, or upgrade Ruby gems.

## ⚡ Actions

| Action | Description |
|--------|-------------|
| `:install` | Install the gem **(default)** |
| `:uninstall` | Uninstall the gem |
| `:upgrade` | Upgrade the gem to the latest (or specified) version |
| `:nothing` | Do nothing (use with notifications) |

## 📋 Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `package_name` | String | Resource name | Gem name (auto-set from resource name) |
| `version` | String | — | Specific version to install |
| `gem_binary` | String or Array | `"gem"` | Path to the gem binary |
| `source` | String | — | Gem source URL |
| `options` | String or Array | `[]` | Additional gem command options |

## 🔍 How It Works

### `:install`
- If the gem is **not installed** → installs it
- If the gem is **installed** and `version` is specified but different → reinstalls with the specified version
- If the gem is **installed** and no version specified (or matches) → does nothing ✅

### `:uninstall`
- Uses `--ignore-dependencies --executables` flags
- If `version` is specified, only removes that version
- If no `version`, removes all versions (`--all`)

### `:upgrade`
- If not installed, or if version is specified and current differs → installs/upgrades
- If already at the requested version → does nothing

> 💡 Itamae checks installed gems by parsing the output of `gem list -l`.

## 🔬 Dry-Run Behavior

The `gem list -l` command runs to check currently installed gems. You see which gems would be installed, upgraded, or removed. No gem operations are executed.

## 📖 Examples

### Install a gem

```ruby
gem_package 'bundler'
```

### Install a specific version

```ruby
gem_package 'bundler' do
  version '2.4.0'
end
```

### Install using a specific Ruby's gem binary

```ruby
gem_package 'puma' do
  gem_binary '/usr/local/ruby/bin/gem'
  version '6.0'
end
```

### Install from an alternate source

```ruby
gem_package 'private-gem' do
  source 'https://gems.example.com'
end
```

### Install with options

```ruby
gem_package 'nokogiri' do
  options '--no-document'
end
```

### Uninstall a gem

```ruby
gem_package 'unused-gem' do
  action :uninstall
end
```

### Upgrade to latest

```ruby
gem_package 'rails' do
  action :upgrade
end
```
