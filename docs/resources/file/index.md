---
title: file
---

Manage file content and attributes on the target system.

## Actions

| Action | Description |
|--------|-------------|
| `:create` | Create or update the file (default) |
| `:delete` | Remove the file |
| `:edit` | Download, modify with a block, then upload |
| `:nothing` | Do nothing (use with notifications) |

## Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `path` | String | Resource name | Path to the file |
| `content` | String | -- | Desired file content |
| `mode` | String | -- | Permissions (e.g., `'0644'`) |
| `owner` | String | -- | File owner |
| `group` | String | -- | File group |
| `block` | Proc | -- | Block for `:edit` action |
| `sensitive` | Boolean | -- | Hide content diff in output |

## Examples

### Create a file with content

```ruby
file '/etc/motd' do
  content 'Welcome to the server!'
  mode '0644'
  owner 'root'
  group 'root'
end
```

### Edit an existing file

```ruby
file '/etc/hosts' do
  action :edit
  block do |content|
    content.gsub!('old-hostname', 'new-hostname')
  end
end
```

### Delete a file

```ruby
file '/tmp/obsolete.conf' do
  action :delete
end
```

### Sensitive content

Hide credentials from log output:

```ruby
file '/etc/app/secrets.yml' do
  content "api_key: #{node[:app][:api_key]}"
  mode '0600'
  owner 'app'
  sensitive true
end
```

### Set permissions only

```ruby
file '/var/log/app.log' do
  mode '0640'
  owner 'app'
  group 'adm'
end
```
