---
title: local_ruby_block
---

Execute arbitrary Ruby code on the **local** machine (where Itamae runs), not on the target. Useful for local logic, logging, or dynamic recipe behavior.

## Actions

| Action | Description |
|--------|-------------|
| `:run` | Execute the block (default) |
| `:nothing` | Do nothing (use with notifications) |

## Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `block` | Proc | -- | Ruby code to execute locally |

## Examples

### Run local logic

```ruby
local_ruby_block 'print info' do
  block do
    puts 'Recipe is running!'
  end
end
```

### Dynamic decisions

```ruby
local_ruby_block 'check environment' do
  block do
    result = run_command('uname -r')
    Itamae.logger.info "Kernel: #{result.stdout.strip}"
  end
end
```

### Conditional resource execution

```ruby
local_ruby_block 'setup feature flag' do
  block do
    result = run_command('cat /etc/feature-flags.json')
    $enable_monitoring = result.stdout.include?('"monitoring": true')
  end
end

package 'prometheus-node-exporter' do
  only_if { $enable_monitoring }
end
```
