---
title: "👥 group"
---

# 👥 group

Manage system groups — create groups and set group IDs.

## ⚡ Actions

| Action | Description |
|--------|-------------|
| `:create` | Create or update the group **(default)** |
| `:nothing` | Do nothing (use with notifications) |

## 📋 Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `groupname` | String | Resource name | Group name (auto-set from resource name) |
| `gid` | Integer | — | Group ID |

## 🔍 How It Works

1. **Check existence** — Queries whether the group exists on the system
2. **Create if missing** — Creates the group with the specified `gid`
3. **Update GID** — If the group exists but `gid` differs from the current value, updates it
4. **Idempotent** — If the group exists with the correct GID, no changes are made

## 🔬 Dry-Run Behavior

Current group existence and GID are queried. You see whether the group would be created or its GID updated.

## 📖 Examples

### Create a group

```ruby
group 'app' do
  gid 3000
end
```

### Create a group for a deploy user

```ruby
group 'deploy'

user 'deploy' do
  gid 'deploy'
  home '/home/deploy'
  create_home true
end
```

### Application group with specific GID

```ruby
group 'webapps' do
  gid 4000
end

%w[app1 app2 app3].each do |app|
  user app do
    gid 4000
    shell '/usr/sbin/nologin'
    system_user true
  end
end
```
