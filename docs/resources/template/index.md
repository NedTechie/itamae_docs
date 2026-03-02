---
title: template
---

Render ERB templates and manage the resulting files on the target system.

## Actions

| Action | Description |
|--------|-------------|
| `:create` | Render and create/update the file (default) |
| `:delete` | Remove the file |
| `:edit` | Download, modify with a block, then upload |
| `:nothing` | Do nothing (use with notifications) |

## Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `path` | String | Resource name | Destination file path |
| `source` | String or Symbol | `:auto` | Template source file (relative to `templates/` directory) |
| `variables` | Hash | `{}` | Variables available in the template |
| `mode` | String | -- | File permissions |
| `owner` | String | -- | File owner |
| `group` | String | -- | File group |
| `content` | String | -- | Direct content (bypasses template) |
| `sensitive` | Boolean | -- | Hide content diff in output |
| `block` | Proc | -- | Block for `:edit` action |

## Template Variables

Variables passed via the `variables` attribute become instance variables in the template:

```ruby
template '/etc/app.conf' do
  source 'app.conf.erb'
  variables(
    port: 8080,
    workers: 4
  )
end
```

In the template:

```erb
port = <%= @port %>
workers = <%= @workers %>
```

The `node` object is also available directly:

```erb
hostname = <%= node[:hostname] %>
```

## Auto Source Resolution

When `source` is `:auto` (the default), Itamae searches for the template relative to the recipe file. For a destination path `/foo/bar/baz.conf`, it checks:

1. `templates/foo/bar/baz.conf.erb`
2. `templates/foo/bar/baz.conf`
3. `templates/bar/baz.conf.erb`
4. `templates/bar/baz.conf`
5. `templates/baz.conf.erb`
6. `templates/baz.conf`

## Examples

### Basic template

**`templates/etc/nginx/conf.d/app.conf.erb`:**

```erb
server {
    listen <%= @port %>;
    server_name <%= @server_name %>;
    root <%= @root %>;
}
```

**Recipe:**

```ruby
template '/etc/nginx/conf.d/app.conf' do
  variables(
    port: 80,
    server_name: 'example.com',
    root: '/var/www/app'
  )
  mode '0644'
  owner 'root'
  notifies :reload, 'service[nginx]'
end
```

### Explicit source

```ruby
template '/etc/myapp.conf' do
  source 'myapp.conf.erb'
  variables(message: 'Hello, World')
end
```

### With node attributes

```ruby
template '/etc/app/database.yml' do
  source 'database.yml.erb'
  variables(
    host: node[:database][:host],
    port: node[:database][:port],
    name: node[:database][:name]
  )
  mode '0600'
  owner 'app'
end
```
