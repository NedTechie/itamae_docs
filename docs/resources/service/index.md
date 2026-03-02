---
title: "🔄 service"
---

# 🔄 service

Manage system services — start, stop, enable, disable, restart, reload.

## ⚡ Actions

| Action | Description |
|--------|-------------|
| `:nothing` | Do nothing **(default)** — use with notifications |
| `:start` | Start the service (only if not running) |
| `:stop` | Stop the service (only if running) |
| `:restart` | Restart the service (always runs) |
| `:reload` | Reload the service config (only if running) |
| `:enable` | Enable the service at boot (only if not enabled) |
| `:disable` | Disable the service at boot (only if enabled) |

> ⚠️ **Note:** The default action is `:nothing`, not `:start`. This is intentional — services are typically used as notification targets. You must explicitly set `action` if you want the service to start/enable.

## 📋 Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | String | Resource name | Service name (auto-set from resource name) |
| `provider` | Symbol | — | Service provider (`:systemd`, `:upstart`, etc.) |

> 💡 When `provider` is set, Itamae appends `_under_<provider>` to all specinfra method calls. For example, with `provider :systemd`, it calls `check_service_is_running_under_systemd` instead of `check_service_is_running`.

## 🔍 How It Works

1. **Query** — Checks if the service is currently running and enabled
2. **Compare** — Determines which state changes are needed
3. **Execute** — Runs only the necessary operations:
   - `:start` and `:stop` are conditional (check state first)
   - `:restart` always runs unconditionally
   - `:reload` only runs if the service is currently running
   - `:enable` and `:disable` are conditional (check state first)

## 🔬 Dry-Run Behavior

Running and enabled states are queried from the system. You see which services would start, stop, enable, or disable. No service state changes are applied.

## 📖 Examples

### Enable and start a service

```ruby
service 'nginx' do
  action [:enable, :start]
end
```

### Restart on configuration change

```ruby
service 'nginx' do
  action :nothing
end

template '/etc/nginx/nginx.conf' do
  source 'nginx.conf.erb'
  notifies :restart, 'service[nginx]'
end
```

### Use a specific provider

```ruby
service 'myapp' do
  provider :systemd
  action [:enable, :start]
end
```

### Stop and disable

```ruby
service 'apache2' do
  action [:stop, :disable]
end
```

### Reload without restart (via subscribes)

```ruby
service 'nginx' do
  action :nothing
  subscribes :reload, 'template[/etc/nginx/conf.d/app.conf]'
end
```

### Multiple actions in sequence

```ruby
service 'app' do
  action [:enable, :start]
end
```

> 💡 Actions in an array are executed in order. `[:enable, :start]` first enables the service, then starts it.
