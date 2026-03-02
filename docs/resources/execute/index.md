---
title: execute
---

Run arbitrary shell commands on the target system.

## Actions

| Action | Description |
|--------|-------------|
| `:run` | Execute the command (default) |
| `:nothing` | Do nothing (use with notifications) |

## Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `command` | String | Resource name | The shell command to run |

## Examples

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

### Conditional execution with guards

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

### Used with notifications

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
