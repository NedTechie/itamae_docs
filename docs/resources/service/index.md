---
title: service
---

Manage system services (start, stop, enable, disable, restart, reload).

## Actions

| Action | Description |
|--------|-------------|
| `:start` | Start the service |
| `:stop` | Stop the service |
| `:restart` | Restart the service |
| `:reload` | Reload the service configuration |
| `:enable` | Enable the service to start on boot |
| `:disable` | Disable the service from starting on boot |
| `:nothing` | Do nothing (default; use with notifications) |

## Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | String | Resource name | Service name |
| `provider` | Symbol | -- | Service provider (`:systemd`, `:upstart`, etc.) |

## Examples

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

### Reload without restart

```ruby
service 'nginx' do
  action :nothing
  subscribes :reload, 'template[/etc/nginx/conf.d/app.conf]'
end
```
