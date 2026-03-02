---
title: group
---

Manage system groups.

## Actions

| Action | Description |
|--------|-------------|
| `:create` | Create the group (default) |
| `:nothing` | Do nothing (use with notifications) |

## Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `groupname` | String | Resource name | Group name |
| `gid` | Integer | -- | Group ID |

## Examples

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
