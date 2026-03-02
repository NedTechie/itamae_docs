---
title: "Example: HAProxy Load Balancer"
---

# HAProxy Load Balancer

Set up HAProxy as a reverse proxy and load balancer with health checks, SSL termination, and stats dashboard.

## Directory Structure

```
cookbooks/
  haproxy/
    default.rb
    templates/
      haproxy.cfg.erb
nodes/
  lb01.json
```

## Node Attributes

```json
{
  "haproxy": {
    "stats_port": 8404,
    "stats_user": "admin",
    "stats_password": "haproxy-stats-pass",
    "frontend_port": 443,
    "frontend_http_port": 80,
    "ssl_cert_path": "/etc/ssl/private/app.pem",
    "backend_port": 3000,
    "backend_servers": [
      { "name": "app01", "address": "10.0.1.10" },
      { "name": "app02", "address": "10.0.1.11" },
      { "name": "app03", "address": "10.0.1.12" }
    ],
    "health_check_path": "/health",
    "health_check_interval": 5000,
    "max_connections": 4096,
    "timeout_connect": 5000,
    "timeout_client": 50000,
    "timeout_server": 50000
  }
}
```

## Recipe

```ruby
# cookbooks/haproxy/default.rb

ha = node['haproxy']

package 'haproxy' do
  action :install
end

directory '/etc/haproxy' do
  owner 'root'
  group 'root'
  mode '0755'
end

directory '/var/lib/haproxy' do
  owner 'haproxy'
  group 'haproxy'
  mode '0750'
end

directory '/var/log/haproxy' do
  owner 'haproxy'
  group 'haproxy'
  mode '0750'
end

# Kernel tuning for high connection counts
execute 'sysctl-haproxy-somaxconn' do
  command 'sysctl -w net.core.somaxconn=4096'
  not_if 'sysctl net.core.somaxconn | grep -q 4096'
end

file '/etc/sysctl.d/99-haproxy.conf' do
  content "net.core.somaxconn = #{ha['max_connections']}\nnet.ipv4.ip_nonlocal_bind = 1\n"
  owner 'root'
  group 'root'
  mode '0644'
end

template '/etc/haproxy/haproxy.cfg' do
  source 'templates/haproxy.cfg.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    stats_port: ha['stats_port'],
    stats_user: ha['stats_user'],
    stats_password: ha['stats_password'],
    frontend_port: ha['frontend_port'],
    frontend_http_port: ha['frontend_http_port'],
    ssl_cert_path: ha['ssl_cert_path'],
    backend_port: ha['backend_port'],
    backend_servers: ha['backend_servers'],
    health_check_path: ha['health_check_path'],
    health_check_interval: ha['health_check_interval'],
    max_connections: ha['max_connections'],
    timeout_connect: ha['timeout_connect'],
    timeout_client: ha['timeout_client'],
    timeout_server: ha['timeout_server']
  )
  notifies :reload, 'service[haproxy]'
end

# Validate config before restart
execute 'haproxy-check-config' do
  command 'haproxy -c -f /etc/haproxy/haproxy.cfg'
  only_if 'test -f /etc/haproxy/haproxy.cfg'
end

service 'haproxy' do
  action [:enable, :start]
end
```

## Templates

### haproxy.cfg.erb

```erb
global
    maxconn <%= @max_connections %>
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    option  forwardfor
    timeout connect <%= @timeout_connect %>ms
    timeout client  <%= @timeout_client %>ms
    timeout server  <%= @timeout_server %>ms

# Stats dashboard
listen stats
    bind *:<%= @stats_port %>
    stats enable
    stats uri /stats
    stats auth <%= @stats_user %>:<%= @stats_password %>

# HTTP to HTTPS redirect
frontend http_front
    bind *:<%= @frontend_http_port %>
    redirect scheme https code 301

# HTTPS frontend
frontend https_front
    bind *:<%= @frontend_port %> ssl crt <%= @ssl_cert_path %>
    default_backend app_servers

# Application backend
backend app_servers
    balance roundrobin
    option httpchk GET <%= @health_check_path %>
<% @backend_servers.each do |server| %>
    server <%= server['name'] %> <%= server['address'] %>:<%= @backend_port %> check inter <%= @health_check_interval %>ms
<% end %>
```

## Running

```bash
itamae ssh -j nodes/lb01.json -h lb01.example.com cookbooks/haproxy/default.rb
```
