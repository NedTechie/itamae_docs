---
title: "Example: Redis Cache"
---

# Redis Cache

Install and configure Redis as an in-memory data store with persistence, memory limits, and kernel tuning for production use.

## Directory Structure

```
cookbooks/
  redis/
    default.rb
    templates/
      redis.conf.erb
      sysctl-redis.conf.erb
nodes/
  cache01.json
```

## Node Attributes

```json
{
  "redis": {
    "version": "7.2",
    "port": 6379,
    "bind_address": "127.0.0.1",
    "maxmemory": "512mb",
    "maxmemory_policy": "allkeys-lru",
    "save_intervals": ["900 1", "300 10", "60 10000"],
    "requirepass": "s3cret-redis-pass",
    "log_level": "notice",
    "data_dir": "/var/lib/redis",
    "log_dir": "/var/log/redis"
  }
}
```

## Recipe

```ruby
# cookbooks/redis/default.rb

redis = node['redis']

package 'redis-server' do
  action :install
end

group 'redis' do
  gid 6379
end

user 'redis' do
  uid 6379
  gid 6379
  home redis['data_dir']
  shell '/usr/sbin/nologin'
  system_user true
end

directory redis['data_dir'] do
  owner 'redis'
  group 'redis'
  mode '0750'
end

directory redis['log_dir'] do
  owner 'redis'
  group 'redis'
  mode '0750'
end

# Kernel tuning for Redis performance
template '/etc/sysctl.d/99-redis.conf' do
  source 'templates/sysctl-redis.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

execute 'apply-sysctl-redis' do
  command 'sysctl -p /etc/sysctl.d/99-redis.conf'
  only_if 'test -f /etc/sysctl.d/99-redis.conf'
end

# Disable Transparent Huge Pages (THP) for Redis
execute 'disable-thp' do
  command 'echo never > /sys/kernel/mm/transparent_hugepage/enabled'
  not_if 'grep -q "\\[never\\]" /sys/kernel/mm/transparent_hugepage/enabled'
end

template '/etc/redis/redis.conf' do
  source 'templates/redis.conf.erb'
  owner 'redis'
  group 'redis'
  mode '0640'
  variables(
    port: redis['port'],
    bind_address: redis['bind_address'],
    maxmemory: redis['maxmemory'],
    maxmemory_policy: redis['maxmemory_policy'],
    save_intervals: redis['save_intervals'],
    requirepass: redis['requirepass'],
    log_level: redis['log_level'],
    data_dir: redis['data_dir'],
    log_dir: redis['log_dir']
  )
  notifies :restart, 'service[redis-server]'
end

service 'redis-server' do
  action [:enable, :start]
end
```

## Templates

### redis.conf.erb

```erb
bind <%= @bind_address %>
port <%= @port %>
daemonize yes
pidfile /var/run/redis/redis-server.pid

loglevel <%= @log_level %>
logfile <%= @log_dir %>/redis-server.log

dir <%= @data_dir %>

<% @save_intervals.each do |interval| %>
save <%= interval %>
<% end %>

maxmemory <%= @maxmemory %>
maxmemory-policy <%= @maxmemory_policy %>

requirepass <%= @requirepass %>

tcp-backlog 511
timeout 0
tcp-keepalive 300
```

### sysctl-redis.conf.erb

```erb
# Redis kernel tuning
vm.overcommit_memory = 1
net.core.somaxconn = 512
```

## Running

```bash
itamae ssh -j nodes/cache01.json -h cache01.example.com cookbooks/redis/default.rb
```
