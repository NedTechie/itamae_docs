---
title: package
---

Install, remove, or manage system packages using the OS package manager.

## Actions

| Action | Description |
|--------|-------------|
| `:install` | Install the package (default) |
| `:remove` | Remove the package |
| `:nothing` | Do nothing (use with notifications) |

## Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | String | Resource name | Package name |
| `version` | String | -- | Specific version to install |
| `options` | String | -- | Additional package manager options |

## Examples

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
%w(git curl wget vim).each do |pkg|
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
