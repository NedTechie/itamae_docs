---
title: "Example: Monitoring Stack"
---

# Monitoring Stack

Deploy a monitoring agent (node_exporter) with health check endpoints and alerting configuration.

## Directory Structure

```
cookbooks/
  monitoring/
    default.rb
    templates/
      node_exporter.service.erb
      alerting.yml.erb
nodes/
  monitoring01.json
```

## Node Attributes

```json
{
  "monitoring": {
    "node_exporter_version": "1.7.0",
    "node_exporter_port": 9100,
    "node_exporter_user": "node_exporter",
    "node_exporter_uid": 9100,
    "textfile_dir": "/var/lib/node_exporter/textfile",
    "health_check_url": "https://health.example.com/ping",
    "alert_email": "ops@example.com"
  }
}
```

## Recipe

```ruby
# cookbooks/monitoring/default.rb

mon = node['monitoring']
version = mon['node_exporter_version']

group mon['node_exporter_user'] do
  gid mon['node_exporter_uid']
end

user mon['node_exporter_user'] do
  uid mon['node_exporter_uid']
  gid mon['node_exporter_uid']
  home '/var/lib/node_exporter'
  shell '/usr/sbin/nologin'
  system_user true
end

directory '/var/lib/node_exporter' do
  owner mon['node_exporter_user']
  group mon['node_exporter_user']
  mode '0755'
end

directory mon['textfile_dir'] do
  owner mon['node_exporter_user']
  group mon['node_exporter_user']
  mode '0755'
end

execute 'download-node-exporter' do
  command "curl -fsSL https://github.com/prometheus/node_exporter/releases/download/v#{version}/node_exporter-#{version}.linux-amd64.tar.gz | tar -xz -C /usr/local/bin --strip-components=1 node_exporter-#{version}.linux-amd64/node_exporter"
  not_if "test -f /usr/local/bin/node_exporter && /usr/local/bin/node_exporter --version 2>&1 | grep -q #{version}"
end

file '/usr/local/bin/node_exporter' do
  owner 'root'
  group 'root'
  mode '0755'
end

template '/etc/systemd/system/node_exporter.service' do
  source 'templates/node_exporter.service.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    user: mon['node_exporter_user'],
    port: mon['node_exporter_port'],
    textfile_dir: mon['textfile_dir']
  )
  notifies :restart, 'service[node_exporter]'
end

http_request '/tmp/health_check' do
  url mon['health_check_url']
end

template '/etc/alerting.yml' do
  source 'templates/alerting.yml.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    alert_email: mon['alert_email'],
    port: mon['node_exporter_port']
  )
end

execute 'systemctl daemon-reload' do
  command 'systemctl daemon-reload'
end

service 'node_exporter' do
  action [:enable, :start]
end
```

## Templates

### node_exporter.service.erb

```erb
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
Type=simple
User=<%= @user %>
ExecStart=/usr/local/bin/node_exporter \
  --web.listen-address=:<%= @port %> \
  --collector.textfile.directory=<%= @textfile_dir %>
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### alerting.yml.erb

```erb
receivers:
  - name: email
    email_configs:
      - to: "<%= @alert_email %>"

route:
  receiver: email
  routes:
    - match:
        job: node_exporter
      receiver: email
```

## Running

```bash
itamae ssh -j nodes/monitoring01.json -h mon01.example.com cookbooks/monitoring/default.rb
```
