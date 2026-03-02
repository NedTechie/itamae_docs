---
title: "📝 template"
---

# 📝 template

Render ERB templates and manage the resulting files on the target system. Inherits from [`remote_file`]({{ '/docs/resources/remote-file/' | relative_url }}) → [`file`]({{ '/docs/resources/file/' | relative_url }}).

## ⚡ Actions

| Action | Description |
|--------|-------------|
| `:create` | Render and create/update the file **(default)** |
| `:delete` | Remove the file |
| `:edit` | Download, modify with a block, then upload |
| `:nothing` | Do nothing (use with notifications) |

## 📋 Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `path` | String | Resource name | Destination file path |
| `source` | String or Symbol | `:auto` | Template source file (relative to `templates/` directory) |
| `variables` | Hash | `{}` | Variables available as `@var` in the template |
| `mode` | String | — | File permissions (e.g., `'0644'`) |
| `owner` | String | — | File owner |
| `group` | String | — | File group |
| `content` | String | — | Direct content (bypasses template rendering) |
| `sensitive` | Boolean | `false` | Hide content diff in output 🔒 |
| `block` | Proc | — | Block for `:edit` action |

> 💡 Inherited from `file`: `path`, `content`, `mode`, `owner`, `group`, `sensitive`, `block`. Inherited from `remote_file`: `source`.

## 🎨 Template Variables

Variables passed via the `variables` attribute become **instance variables** (`@var`) in the template:

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

The `node` object is also directly available:

```erb
hostname = <%= node[:hostname] %>
```

> ⚙️ Templates use `ERB.new(template, trim_mode: '-')`, so you can use `<%-` and `-%>` for whitespace control.

## 🔎 Auto Source Resolution

When `source` is `:auto` (the default), Itamae searches for the template relative to the recipe file. For a destination path `/foo/bar/baz.conf`, it checks (with `.erb` extension tried first):

| Priority | Search Path |
|----------|-------------|
| 1️⃣ | `templates/foo/bar/baz.conf.erb` |
| 2️⃣ | `templates/foo/bar/baz.conf` |
| 3️⃣ | `templates/bar/baz.conf.erb` |
| 4️⃣ | `templates/bar/baz.conf` |
| 5️⃣ | `templates/baz.conf.erb` |
| 6️⃣ | `templates/baz.conf` |

## 🔬 Dry-Run Behavior

In [dry-run mode]({{ '/docs/dry-run/' | relative_url }}), the ERB template is **fully rendered** and uploaded as a temp file. A unified diff is shown against the existing file, so you see the **exact rendered output** that would be written. The file is not moved into place.

## 📖 Examples

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

### Conditional content with ERB

```erb
<% if @ssl_enabled %>
listen 443 ssl;
ssl_certificate <%= @ssl_cert %>;
<% else %>
listen 80;
<% end %>
```

## 🧬 Inheritance Chain

```
file → remote_file → template
```

Template inherits all attributes and behavior from `file` and `remote_file`.
