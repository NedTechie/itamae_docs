---
title: "💻 local_ruby_block"
---

# 💻 local_ruby_block

Execute arbitrary Ruby code on the **local** machine (where Itamae runs), not on the target. Useful for local logic, logging, or dynamic recipe behavior.

## ⚡ Actions

| Action | Description |
|--------|-------------|
| `:run` | Execute the block **(default)** |
| `:nothing` | Do nothing (use with notifications) |

## 📋 Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `block` | Proc | — | Ruby code to execute locally |

> 💡 This resource has **no `default_name` attribute** — the resource name is just a label for logging purposes.

## 🔍 How It Works

1. **Execute** — Calls the Ruby block on the local machine
2. **CWD support** — If the common `cwd` attribute is set, changes directory via `Dir.chdir(cwd)` before executing the block
3. **Local context** — The block runs in the Itamae process, with access to `run_command` for executing shell commands on the target

## 🔬 Dry-Run Behavior

> ⚠️ **Important:** The Ruby block is **not executed** in [dry-run mode]({{ '/docs/dry-run/' | relative_url }}). The block is inside the `action_run` method, which is skipped entirely. There is no way to preview what a `local_ruby_block` would do.

## 📖 Examples

### Run local logic

```ruby
local_ruby_block 'print info' do
  block do
    puts 'Recipe is running!'
  end
end
```

### Dynamic decisions 🔀

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

### Logging and debugging 🐛

```ruby
local_ruby_block 'debug info' do
  block do
    Itamae.logger.info "Node attributes: #{node.to_hash}"
    Itamae.logger.info "Running on: #{run_command('hostname').stdout.strip}"
  end
end
```
