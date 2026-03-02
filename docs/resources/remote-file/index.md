---
title: remote_file
---

Upload files from the local machine (where Itamae runs) to the target system.

## Actions

| Action | Description |
|--------|-------------|
| `:create` | Upload and create/update the file (default) |
| `:delete` | Remove the file |
| `:edit` | Download, modify with a block, then upload |
| `:nothing` | Do nothing (use with notifications) |

## Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `path` | String | Resource name | Destination path on the target |
| `source` | String or Symbol | `:auto` | Source file path (relative to `files/` directory) |
| `mode` | String | -- | File permissions |
| `owner` | String | -- | File owner |
| `group` | String | -- | File group |
| `content` | String | -- | Direct content (bypasses source file) |
| `sensitive` | Boolean | -- | Hide content diff in output |
| `block` | Proc | -- | Block for `:edit` action |

## Auto Source Resolution

When `source` is `:auto` (the default), Itamae searches for the source file relative to the recipe. For a destination path `/foo/bar/baz.conf`, it checks:

1. `files/foo/bar/baz.conf` (recommended)
2. `files/bar/baz.conf`
3. `files/baz.conf`

## Examples

### Upload a configuration file

```ruby
remote_file '/etc/nginx/conf.d/static.conf' do
  mode '0644'
  owner 'root'
end
```

With auto source, place the file at `files/etc/nginx/conf.d/static.conf` next to your recipe.

### Explicit source

```ruby
remote_file '/etc/app.conf' do
  source 'config/app.conf'
  mode '0644'
end
```

### Set ownership and permissions

```ruby
remote_file '/usr/local/bin/deploy.sh' do
  source 'scripts/deploy.sh'
  mode '0755'
  owner 'deploy'
  group 'deploy'
end
```
