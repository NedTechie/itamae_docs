---
title: "🧱 Resources"
---

# 🧱 Resources

Resources are the building blocks of Itamae recipes. Each resource describes a piece of infrastructure and its desired state. Itamae ships with **15 built-in resource types**.

## 🔧 Common Attributes

All resources share these attributes:

| Attribute | Type | Description |
|-----------|------|-------------|
| `action` | Symbol or Array | Action(s) to perform. Each resource has its own set of valid actions. |
| `user` | String | Execute resource commands as this user. |
| `cwd` | String | Working directory for commands. |
| `only_if` | String | Guard — execute resource only if this shell command succeeds (exit 0). |
| `not_if` | String | Guard — skip resource if this shell command succeeds (exit 0). |

> 💡 **Tip:** Guards run real shell commands on the target — even in [dry-run mode]({{ '/docs/dry-run/' | relative_url }}).

## 🔔 Notifications

Resources can notify other resources when they change:

```ruby
template '/etc/nginx/nginx.conf' do
  source 'nginx.conf.erb'
  notifies :restart, 'service[nginx]'
end
```

### `notifies`

Trigger an action on another resource:

```ruby
notifies :action, 'resource_type[name]'           # delayed (default)
notifies :action, 'resource_type[name]', :delayed
notifies :action, 'resource_type[name]', :immediately
```

### `subscribes`

Listen for changes on another resource:

```ruby
service 'nginx' do
  subscribes :restart, 'template[/etc/nginx/nginx.conf]'
  action :nothing
end
```

## ⏱️ Timing

- **`:delayed`** (default) — Run the notification after the entire recipe completes. Duplicate delayed notifications are coalesced.
- **`:immediately`** — Run the notification right after the notifying resource executes.

## 📚 Built-in Resources

| Resource | Description |
|----------|-------------|
| 📂 [directory](directory/) | Manage directories |
| ⚡ [execute](execute/) | Run shell commands |
| 📄 [file](file/) | Manage file content and attributes |
| 💎 [gem_package](gem-package/) | Install Ruby gems |
| 🐙 [git](git/) | Clone and sync git repositories |
| 👥 [group](group/) | Manage system groups |
| 🌐 [http_request](http-request/) | Make HTTP requests and save responses |
| 🔗 [link](link/) | Create symbolic links |
| 💻 [local_ruby_block](local-ruby-block/) | Execute local Ruby code |
| 📦 [package](package/) | Install system packages |
| 📁 [remote_directory](remote-directory/) | Upload directories to targets |
| 📤 [remote_file](remote-file/) | Upload files to targets |
| 🔄 [service](service/) | Manage system services |
| 📝 [template](template/) | Render ERB templates |
| 👤 [user](user/) | Manage system users |

## 🔄 Resource Lifecycle

Each resource goes through these steps when executed:

1. 🏗️ **Initialize** — Resource created with attributes from the DSL block
2. 🛡️ **Evaluate guards** — `only_if`/`not_if` conditions checked (commands run on target)
3. 🔍 **Pre-action** — Gather desired state, upload temp files for comparison
4. 📊 **Query current state** — Check existing state on the target via specinfra
5. 📈 **Show differences** — Display what would change (attribute diffs, file content diffs)
6. ⚙️ **Execute action** — Apply changes (⏭️ skipped in [dry-run mode]({{ '/docs/dry-run/' | relative_url }}))
7. ✅ **Verify** — Run verification commands (⏭️ skipped in dry-run)
8. 🔔 **Notify** — Trigger any notifications/subscriptions

## 🧬 Inheritance Hierarchy

Resources form an inheritance tree. Child resources inherit all parent attributes:

```
Base (action, user, cwd)
├── 📦 Package
├── 🔄 Service
├── 📄 File (path, content, mode, owner, group, sensitive, block)
│   ├── 📤 RemoteFile (+source)
│   │   └── 📝 Template (+variables)
│   └── 🌐 HttpRequest (+url, headers, message, redirect_limit)
├── 📂 Directory
├── ⚡ Execute
├── 🔗 Link
├── 👤 User
├── 👥 Group
├── 🐙 Git
├── 💎 GemPackage
├── 📁 RemoteDirectory
└── 💻 LocalRubyBlock
```

> 💡 For example, `template` inherits `mode`, `owner`, `group`, and `sensitive` from `file` — you don't need to check the `file` docs separately.
