---
title: "🔔 Notifications"
---

Notifications allow resources to trigger actions on other resources when they make changes. This is the primary mechanism for restarting services after configuration changes.

## 📣 `notifies`

Trigger an action on another resource when this resource changes:

```ruby
template '/etc/nginx/nginx.conf' do
  source 'nginx.conf.erb'
  notifies :restart, 'service[nginx]'
end

service 'nginx' do
  action [:enable, :start]
end
```

### 📝 Syntax

```ruby
notifies :action, 'resource_type[resource_name]'
notifies :action, 'resource_type[resource_name]', :timing
```

### ⏱️ Timing

| Timing | Description |
|--------|-------------|
| `:delayed` | Run after the entire recipe completes (default). Duplicates are coalesced. |
| `:delay` | Alias for `:delayed` |
| `:immediately` | Run right after the notifying resource executes |

### ⏳ Delayed (default)

```ruby
template '/etc/nginx/nginx.conf' do
  source 'nginx.conf.erb'
  notifies :restart, 'service[nginx]'           # delayed by default
  notifies :restart, 'service[nginx]', :delayed  # explicit
end
```

If multiple resources notify the same target with `:delayed` timing, the action runs only once at the end.

### ⚡ Immediate

```ruby
package 'nginx' do
  notifies :start, 'service[nginx]', :immediately
end
```

## 👀 `subscribes`

The inverse of `notifies` -- a resource watches another resource and acts when it changes:

```ruby
service 'nginx' do
  action :nothing
  subscribes :restart, 'template[/etc/nginx/nginx.conf]'
end

template '/etc/nginx/nginx.conf' do
  source 'nginx.conf.erb'
end
```

### Syntax

```ruby
subscribes :action, 'resource_type[resource_name]'
subscribes :action, 'resource_type[resource_name]', :timing
```

## 📖 Common Patterns

### 🔄 Restart service on config change

```ruby
service 'app' do
  action [:enable, :start]
end

template '/etc/app/config.yml' do
  source 'config.yml.erb'
  variables(port: node[:app][:port])
  notifies :restart, 'service[app]'
end
```

### ♻️ Reload instead of restart

```ruby
template '/etc/nginx/conf.d/site.conf' do
  source 'site.conf.erb'
  notifies :reload, 'service[nginx]'
end
```

### 🔗 Chain multiple notifications

```ruby
git '/opt/app' do
  repository 'https://github.com/org/app.git'
  revision 'main'
  notifies :run, 'execute[bundle install]', :immediately
  notifies :restart, 'service[app]'
end

execute 'bundle install' do
  action :nothing
  command 'cd /opt/app && bundle install --deployment'
end

service 'app' do
  action [:enable, :start]
end
```

### 🔧 Daemon reload for systemd

```ruby
execute 'systemctl daemon-reload' do
  action :nothing
end

template '/etc/systemd/system/app.service' do
  source 'app.service.erb'
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
  notifies :restart, 'service[app]'
end
```

## 🏷️ Resource Reference Format

Notifications reference resources using the format:

```
resource_type[resource_name]
```

Examples:
- `service[nginx]`
- `template[/etc/nginx/nginx.conf]`
- `execute[bundle install]`
- `package[redis]`

The resource name is typically the first argument passed when declaring the resource.
