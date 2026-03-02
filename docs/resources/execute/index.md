---
title: "⚡ execute"
---

# ⚡ execute

Run arbitrary shell commands on the target system.

## ⚡ Actions

| Action | Description |
|--------|-------------|
| `:run` | Execute the command **(default)** |
| `:nothing` | Do nothing (use with notifications) |

## 📋 Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `command` | String | Resource name | The shell command to run (auto-set from resource name) |

> 💡 Common attributes `user` and `cwd` are especially useful with `execute` — run commands as a specific user or in a specific directory.

## 🔍 How It Works

1. **Evaluate guards** — `only_if`/`not_if` commands run first to decide if the resource should execute
2. **Run command** — Executes the command on the target system
3. **Always marks as changed** — Every successful execution is considered an update (calls `updated!`)

> ⚠️ **Important:** Because `execute` always marks itself as changed, it will always trigger notifications. Use guards (`not_if`/`only_if`) to make execute resources idempotent.

## 🔬 Dry-Run Behavior

In [dry-run mode]({{ '/docs/dry-run/' | relative_url }}), the command itself is **skipped**, but you see:

```
 INFO :   execute[apt-get update]
 INFO :     executed will change from 'false' to 'true'
```

> ⚠️ Guards (`only_if`/`not_if`) **still run** their commands in dry-run mode — this is necessary to determine whether the resource would execute.

## 📖 Examples

### Basic command

```ruby
execute 'apt-get update'
```

### Named resource with explicit command

```ruby
execute 'update package cache' do
  command 'apt-get update -qq'
end
```

### Idempotent execution with guards 🛡️

```ruby
execute 'create an empty file' do
  command 'touch /path/to/file'
  not_if 'test -e /path/to/file'
end
```

```ruby
execute 'initialize database' do
  command '/opt/app/bin/db-init'
  only_if 'test -f /opt/app/bin/db-init'
  not_if 'test -f /opt/app/.db-initialized'
end
```

### Run as a specific user

```ruby
execute 'bundle install' do
  command 'cd /opt/app && bundle install --deployment'
  user 'deploy'
  cwd '/opt/app'
end
```

### Used with notifications 🔔

```ruby
execute 'compile assets' do
  action :nothing
  command 'cd /opt/app && rake assets:precompile'
end

git '/opt/app' do
  repository 'https://github.com/user/app.git'
  notifies :run, 'execute[compile assets]', :immediately
end
```

### Run with error handling

```ruby
execute 'optional cleanup' do
  command 'rm -rf /tmp/build-cache'
  only_if 'test -d /tmp/build-cache'
end
```
