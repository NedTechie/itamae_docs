---
title: "📄 file"
---

# 📄 file

Manage file content and attributes on the target system. This is the base resource for `remote_file`, `template`, and `http_request`.

## ⚡ Actions

| Action | Description |
|--------|-------------|
| `:create` | Create or update the file **(default)** |
| `:delete` | Remove the file |
| `:edit` | Download, modify with a block, then upload |
| `:nothing` | Do nothing (use with notifications) |

## 📋 Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `path` | String | Resource name | Path to the file (auto-set from resource name) |
| `content` | String | — | Desired file content |
| `mode` | String | — | Permissions (e.g., `'0644'`) |
| `owner` | String | — | File owner |
| `group` | String | — | File group |
| `block` | Proc | `proc {}` | Block for `:edit` action — receives current content as argument |
| `sensitive` | Boolean | `false` | Hide content diff in log output 🔒 |

## 🔍 How It Works

1. **Check existence** — Queries whether the file exists on the target
2. **SHA256 comparison** — Computes local digest vs. remote `sha256sum` for fast content comparison
3. **Temp file upload** — Uploads desired content to a temp path on the target
4. **Diff comparison** — Runs `diff -q` to detect changes, `diff -u` for display
5. **Apply** — If content changed, moves the temp file into place and sets mode/owner/group

### 📝 The `:edit` Action

The `:edit` action downloads the existing file content, passes it to your block for in-place modification, then uploads the result:

```ruby
file '/etc/hosts' do
  action :edit
  block do |content|
    content.gsub!('old-hostname', 'new-hostname')
  end
end
```

> ⚠️ The block receives the content string and must modify it in-place (using `gsub!`, `<<`, etc.).

## 🔬 Dry-Run Behavior

In [dry-run mode]({{ '/docs/dry-run/' | relative_url }}), the file resource **uploads a temp file and runs a diff** — so you get **full unified diffs** showing exactly what would change. The actual file is never moved into place. Files marked `sensitive true` suppress the diff output.

## 📖 Examples

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

### Sensitive content 🔒

Hide credentials from log output:

```ruby
file '/etc/app/secrets.yml' do
  content "api_key: #{node[:app][:api_key]}"
  mode '0600'
  owner 'app'
  sensitive true
end
```

### Set permissions only (no content change)

```ruby
file '/var/log/app.log' do
  mode '0640'
  owner 'app'
  group 'adm'
end
```

## 🧬 Inheritance

`file` is the parent of [`remote_file`]({{ '/docs/resources/remote-file/' | relative_url }}), [`template`]({{ '/docs/resources/template/' | relative_url }}), and [`http_request`]({{ '/docs/resources/http-request/' | relative_url }}). All child resources inherit the attributes above.
