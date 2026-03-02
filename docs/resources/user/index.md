---
title: user
---

Manage system user accounts.

## Actions

| Action | Description |
|--------|-------------|
| `:create` | Create or update the user (default) |
| `:nothing` | Do nothing (use with notifications) |

## Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `username` | String | Resource name | Username |
| `uid` | Integer | -- | User ID |
| `gid` | Integer or String | -- | Primary group ID or name |
| `home` | String | -- | Home directory path |
| `shell` | String | -- | Login shell |
| `password` | String | -- | Encrypted password hash |
| `system_user` | Boolean | -- | Create as a system user |
| `create_home` | Boolean | -- | Create home directory |

## Examples

### Create a user

```ruby
user 'deploy' do
  uid 1001
  home '/home/deploy'
  shell '/bin/bash'
  create_home true
end
```

### System user for a service

```ruby
user 'app' do
  system_user true
  home '/opt/app'
  shell '/usr/sbin/nologin'
end
```

### User with group

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
