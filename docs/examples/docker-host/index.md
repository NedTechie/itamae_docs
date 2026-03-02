---
title: "Example: Docker Host"
---

# Docker Host

Provision a Docker host with daemon configuration, log rotation, and user access.

## Directory Structure

```
cookbooks/
  docker/
    default.rb
    templates/
      daemon.json.erb
      docker-logrotate.erb
nodes/
  docker01.json
```

## Node Attributes

```json
{
  "docker": {
    "storage_driver": "overlay2",
    "log_driver": "json-file",
    "log_max_size": "50m",
    "log_max_file": 3,
    "registry_mirrors": ["https://mirror.example.com"],
    "users": ["deploy", "ci"]
  }
}
```

## Recipe

```ruby
# cookbooks/docker/default.rb

%w[apt-transport-https ca-certificates curl gnupg].each do |pkg|
  package pkg do
    action :install
  end
end

execute 'add-docker-gpg-key' do
  command 'curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg'
  not_if 'test -f /usr/share/keyrings/docker-archive-keyring.gpg'
end

execute 'add-docker-repo' do
  command 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list'
  not_if 'test -f /etc/apt/sources.list.d/docker.list'
end

execute 'apt-update-docker' do
  command 'apt-get update'
end

package 'docker-ce' do
  action :install
end

package 'docker-compose-plugin' do
  action :install
end

directory '/etc/docker' do
  owner 'root'
  group 'root'
  mode '0755'
end

group 'docker' do
  action :create
end

node['docker']['users'].each do |u|
  execute "add-#{u}-to-docker" do
    command "usermod -aG docker #{u}"
    not_if "id -nG #{u} | grep -qw docker"
  end
end

template '/etc/docker/daemon.json' do
  source 'templates/daemon.json.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    storage_driver: node['docker']['storage_driver'],
    log_driver: node['docker']['log_driver'],
    log_max_size: node['docker']['log_max_size'],
    log_max_file: node['docker']['log_max_file'],
    registry_mirrors: node['docker']['registry_mirrors']
  )
  notifies :restart, 'service[docker]'
end

file '/etc/logrotate.d/docker' do
  content <<~CONF
    /var/lib/docker/containers/*/*.log {
      daily
      rotate 7
      compress
      missingok
      notifempty
      copytruncate
    }
  CONF
  owner 'root'
  group 'root'
  mode '0644'
end

service 'docker' do
  action [:enable, :start]
end
```

## Templates

### daemon.json.erb

```erb
{
  "storage-driver": "<%= @storage_driver %>",
  "log-driver": "<%= @log_driver %>",
  "log-opts": {
    "max-size": "<%= @log_max_size %>",
    "max-file": "<%= @log_max_file %>"
  },
  "registry-mirrors": <%= @registry_mirrors.to_json %>
}
```

## Running

```bash
itamae ssh -j nodes/docker01.json -h docker01.example.com cookbooks/docker/default.rb
```
