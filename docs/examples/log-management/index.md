---
title: "Example: Log Management"
---

# Log Management

Configure centralized logging with rsyslog forwarding to a remote server, structured log formats, and logrotate policies.

## Directory Structure

```
cookbooks/
  logging/
    default.rb
    templates/
      rsyslog-forward.conf.erb
      logrotate-app.erb
      journald.conf.erb
nodes/
  app01.json
```

## Node Attributes

```json
{
  "logging": {
    "remote_host": "logs.example.com",
    "remote_port": 514,
    "protocol": "tcp",
    "app_name": "myapp",
    "app_log_dir": "/var/log/myapp",
    "app_user": "deploy",
    "rotate_count": 14,
    "rotate_size": "100M",
    "journal_max_size": "500M",
    "journal_max_age": "30d"
  }
}
```

## Recipe

```ruby
# cookbooks/logging/default.rb

log = node['logging']

# --- rsyslog for remote forwarding ---

package 'rsyslog' do
  action :install
end

directory '/etc/rsyslog.d' do
  owner 'root'
  group 'root'
  mode '0755'
end

template '/etc/rsyslog.d/50-remote.conf' do
  source 'templates/rsyslog-forward.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    remote_host: log['remote_host'],
    remote_port: log['remote_port'],
    protocol: log['protocol'],
    app_name: log['app_name']
  )
  notifies :restart, 'service[rsyslog]'
end

service 'rsyslog' do
  action [:enable, :start]
end

# --- Application log directory ---

directory log['app_log_dir'] do
  owner log['app_user']
  group log['app_user']
  mode '0755'
end

# --- Logrotate for application logs ---

template "/etc/logrotate.d/#{log['app_name']}" do
  source 'templates/logrotate-app.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    app_log_dir: log['app_log_dir'],
    rotate_count: log['rotate_count'],
    rotate_size: log['rotate_size'],
    app_user: log['app_user']
  )
end

# --- Journald size limits ---

template '/etc/systemd/journald.conf.d/size.conf' do
  source 'templates/journald.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    max_size: log['journal_max_size'],
    max_age: log['journal_max_age']
  )
  notifies :restart, 'service[systemd-journald]'
end

directory '/etc/systemd/journald.conf.d' do
  owner 'root'
  group 'root'
  mode '0755'
end

service 'systemd-journald' do
  action [:enable, :start]
end
```

## Templates

### rsyslog-forward.conf.erb

```erb
# Forward application logs to remote syslog server
<% if @protocol == 'tcp' %>
*.* @@<%= @remote_host %>:<%= @remote_port %>
<% else %>
*.* @<%= @remote_host %>:<%= @remote_port %>
<% end %>

# Tag application messages
if $programname == '<%= @app_name %>' then {
    action(type="omfwd"
           target="<%= @remote_host %>"
           port="<%= @remote_port %>"
           protocol="<%= @protocol %>"
           template="RSYSLOG_SyslogProtocol23Format")
    stop
}
```

### logrotate-app.erb

```erb
<%= @app_log_dir %>/*.log {
    daily
    rotate <%= @rotate_count %>
    size <%= @rotate_size %>
    compress
    delaycompress
    missingok
    notifempty
    create 0644 <%= @app_user %> <%= @app_user %>
    sharedscripts
    postrotate
        systemctl reload rsyslog 2>/dev/null || true
    endscript
}
```

### journald.conf.erb

```erb
[Journal]
SystemMaxUse=<%= @max_size %>
MaxRetentionSec=<%= @max_age %>
Compress=yes
ForwardToSyslog=yes
```

## Running

```bash
itamae ssh -j nodes/app01.json -h app01.example.com cookbooks/logging/default.rb
```
