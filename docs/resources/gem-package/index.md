---
title: gem_package
---

Install, uninstall, or upgrade Ruby gems.

## Actions

| Action | Description |
|--------|-------------|
| `:install` | Install the gem (default) |
| `:uninstall` | Uninstall the gem |
| `:upgrade` | Upgrade the gem to latest version |
| `:nothing` | Do nothing (use with notifications) |

## Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `package_name` | String | Resource name | Gem name |
| `version` | String | -- | Specific version to install |
| `gem_binary` | String or Array | `"gem"` | Path to the gem binary |
| `source` | String | -- | Gem source URL |
| `options` | String or Array | `[]` | Additional gem command options |

## Examples

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
