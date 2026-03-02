---
title: "🐙 git"
---

# 🐙 git

Clone and synchronize git repositories on the target system.

## ⚡ Actions

| Action | Description |
|--------|-------------|
| `:sync` | Clone or update the repository **(default)** |
| `:nothing` | Do nothing (use with notifications) |

## 📋 Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `destination` | String | Resource name | Local path for the repository (auto-set from resource name) |
| `repository` | String | **required** ⚠️ | Git repository URL |
| `revision` | String | — | Branch, tag, or commit SHA to checkout |
| `recursive` | Boolean | `false` | Clone with `--recursive` (include submodules) |
| `depth` | Integer | — | Shallow clone depth (`--depth N`) |

## 🔍 How It Works

The `:sync` action uses a **deploy branch strategy**:

1. ✅ Verifies `git` is available on the target system
2. 📂 If the destination is empty, clones the repository (with `--recursive` and `--depth` if set)
3. 🔍 Resolves the target revision to a commit SHA
4. 📊 Compares with the current HEAD
5. 🔄 If different, creates a `deploy` branch pointing to the target revision:
   - Renames existing `deploy` branch to `deploy-old`
   - Fetches from origin
   - Checks out the target as a new `deploy` branch
   - Cleans up `deploy-old`

> 💡 The fetch from origin is memoized — only runs once per resource execution regardless of how many resolution steps are needed.

## 🔬 Dry-Run Behavior

Destination directory existence is verified. The repository is not cloned, fetched, or checked out.

## 📖 Examples

### Clone a repository

```ruby
git '/opt/app' do
  repository 'https://github.com/user/app.git'
end
```

### Clone a specific branch/tag

```ruby
git '/opt/app' do
  repository 'https://github.com/user/app.git'
  revision 'v2.0'
end
```

### Shallow clone (faster) ⏩

```ruby
git '/opt/app' do
  repository 'https://github.com/user/app.git'
  depth 1
end
```

### Recursive clone with submodules

```ruby
git '/opt/app' do
  repository 'https://github.com/user/app.git'
  revision 'main'
  recursive true
end
```

### Notify on update 🔔

```ruby
git '/opt/app' do
  repository 'https://github.com/user/app.git'
  revision 'main'
  notifies :run, 'execute[bundle install]', :immediately
end

execute 'bundle install' do
  action :nothing
  command 'cd /opt/app && bundle install'
  user 'deploy'
end
```

### Clone as a specific user

```ruby
git '/home/deploy/app' do
  repository 'https://github.com/user/app.git'
  revision 'main'
  user 'deploy'
end
```
