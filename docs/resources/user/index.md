---
title: "👤 user"
---

# 👤 user

Manage system user accounts — create users and update their attributes.

## ⚡ Actions

| Action | Description |
|--------|-------------|
| `:create` | Create or update the user **(default)** |
| `:nothing` | Do nothing (use with notifications) |

## 📋 Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `username` | String | Resource name | Username (auto-set from resource name) |
| `uid` | Integer | — | User ID |
| `gid` | Integer or String | — | Primary group ID or group name |
| `home` | String | — | Home directory path |
| `shell` | String | — | Login shell (e.g., `/bin/bash`, `/usr/sbin/nologin`) |
| `password` | String | — | Encrypted password hash |
| `system_user` | Boolean | — | Create as a system user (lower UID range) |
| `create_home` | Boolean | `false` | Create home directory if it doesn't exist |

## 🔍 How It Works

### Creating a new user
When the user doesn't exist, Itamae creates it with all specified attributes in a single `adduser` call.

### Updating an existing user
When the user exists, Itamae **selectively updates** only the attributes that differ from the current state:

| Attribute | Update behavior |
|-----------|----------------|
| `uid` | Updated if different from current |
| `gid` | Updated if different from current |
| `home` | Updated if different from current |
| `shell` | Updated if different from current |
| `password` | Updated if different from current encrypted hash |

> 💡 **GID as string:** If `gid` is a group name (String), Itamae resolves it to a numeric GID by querying the system during `pre_action`.

## 🔬 Dry-Run Behavior

Current uid, gid, home, and shell are queried from the system. You see exactly which attributes would be created or updated.

## 📖 Examples

### Create a user

```ruby
user 'deploy' do
  uid 1001
  home '/home/deploy'
  shell '/bin/bash'
  create_home true
end
```

### System user for a service 🔒

```ruby
user 'app' do
  system_user true
  home '/opt/app'
  shell '/usr/sbin/nologin'
end
```

### User with a group name

```ruby
group 'developers' do
  gid 2000
end

user 'dev' do
  gid 'developers'
  home '/home/dev'
  shell '/bin/zsh'
  create_home true
end
```

### Complete user setup with SSH directory

```ruby
user 'alice' do
  uid 2001
  home '/home/alice'
  shell '/bin/bash'
  create_home true
end

directory '/home/alice/.ssh' do
  owner 'alice'
  group 'alice'
  mode '0700'
end

file '/home/alice/.ssh/authorized_keys' do
  content node[:users][:alice][:ssh_key]
  owner 'alice'
  mode '0600'
end
```
