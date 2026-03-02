---
title: "📁 remote_directory"
---

# 📁 remote_directory

Upload an entire directory from the local machine (where Itamae runs) to the target system.

## ⚡ Actions

| Action | Description |
|--------|-------------|
| `:create` | Upload the directory **(default)** |
| `:delete` | Remove the directory |
| `:nothing` | Do nothing (use with notifications) |

## 📋 Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `path` | String | Resource name | Destination path on the target (auto-set from resource name) |
| `source` | String | **required** ⚠️ | Source directory (relative to recipe file) |
| `mode` | String | — | Directory permissions |
| `owner` | String | — | Directory owner |
| `group` | String | — | Directory group |

## 🔍 How It Works

1. 📁 **Resolve source** — Expands the `source` path relative to the recipe file's directory
2. 📤 **Upload** — Uploads the entire local directory to a temp path on the target via the backend
3. 🔧 **Apply attributes** — Sets `mode`, `owner`, and `group` on the temp directory
4. 📊 **Compare** — Runs `diff -q` to check if the destination differs from the uploaded content
5. ♻️ **Replace** — If different, removes the existing directory and moves the temp directory into place

> 💡 During `show_differences`, a recursive diff (`diff -u -r`) is shown if the destination directory already exists.

## 🔬 Dry-Run Behavior

The source directory is uploaded to a temp path for comparison. A recursive diff shows what would change. The actual directory is not replaced.

## 📖 Examples

### Upload a configuration directory

```ruby
remote_directory '/etc/app/config' do
  source 'files/config'
  mode '0755'
  owner 'app'
  group 'app'
end
```

### Upload static assets

```ruby
remote_directory '/var/www/static' do
  source 'files/static'
  mode '0755'
  owner 'www-data'
end
```

### Upload with notification 🔔

```ruby
remote_directory '/etc/nginx/conf.d' do
  source 'files/nginx-configs'
  mode '0755'
  owner 'root'
  notifies :reload, 'service[nginx]'
end
```
