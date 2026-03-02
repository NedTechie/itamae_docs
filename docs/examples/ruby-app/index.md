---
title: "Example: Ruby Application Deployment"
---

# Ruby Application Deployment

Deploy a Ruby web application with Puma, managed by systemd, with log rotation and Nginx integration.

## Directory Structure

```
cookbooks/
  ruby-app/
    default.rb
    templates/
      puma.service.erb
      puma.rb.erb
      env.erb
nodes/
  app01.json
```

## Node Attributes

```json
{
  "app": {
    "name": "myapp",
    "user": "deploy",
    "uid": 1001,
    "deploy_to": "/var/www/myapp",
    "repository": "https://github.com/example/myapp.git",
    "revision": "main",
    "ruby_version": "3.2.2",
    "puma_workers": 2,
    "puma_threads_min": 1,
    "puma_threads_max": 5,
    "puma_port": 3000,
    "environment": "production",
    "secret_key_base": "abc123..."
  }
}
```

## Recipe

```ruby
# cookbooks/ruby-app/default.rb

app  = node['app']
user = app['user']
home = "/home/#{user}"
deploy_to = app['deploy_to']

group user do
  gid app['uid']
end

user user do
  uid app['uid']
  gid app['uid']
  home home
  shell '/bin/bash'
  create_home true
end

%w[releases shared shared/log shared/tmp shared/config].each do |dir|
  directory "#{deploy_to}/#{dir}" do
    owner user
    group user
    mode '0755'
  end
end

package 'build-essential' do
  action :install
end

gem_package 'bundler' do
  version '2.4.0'
end

git "#{deploy_to}/releases/current" do
  repository app['repository']
  revision app['revision']
  user user
end

template "#{deploy_to}/shared/config/puma.rb" do
  source 'templates/puma.rb.erb'
  owner user
  group user
  mode '0644'
  variables(
    deploy_to: deploy_to,
    workers: app['puma_workers'],
    threads_min: app['puma_threads_min'],
    threads_max: app['puma_threads_max'],
    port: app['puma_port']
  )
  notifies :restart, 'service[puma]'
end

template "#{deploy_to}/shared/.env" do
  source 'templates/env.erb'
  owner user
  group user
  mode '0600'
  variables(
    environment: app['environment'],
    secret_key_base: app['secret_key_base'],
    port: app['puma_port']
  )
  notifies :restart, 'service[puma]'
end

template '/etc/systemd/system/puma.service' do
  source 'templates/puma.service.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    user: user,
    deploy_to: deploy_to,
    app_name: app['name']
  )
  notifies :restart, 'service[puma]'
end

execute 'bundle install' do
  command "cd #{deploy_to}/releases/current && bundle install --deployment --without development test"
  user user
  not_if "cd #{deploy_to}/releases/current && bundle check"
end

link "#{deploy_to}/current" do
  to "#{deploy_to}/releases/current"
end

execute 'systemctl daemon-reload' do
  command 'systemctl daemon-reload'
end

service 'puma' do
  action [:enable, :start]
end
```

## Templates

### puma.rb.erb

```erb
directory "<%= @deploy_to %>/releases/current"
bind "tcp://0.0.0.0:<%= @port %>"
workers <%= @workers %>
threads <%= @threads_min %>, <%= @threads_max %>
stdout_redirect "<%= @deploy_to %>/shared/log/puma.stdout.log", "<%= @deploy_to %>/shared/log/puma.stderr.log", true
pidfile "<%= @deploy_to %>/shared/tmp/puma.pid"
state_path "<%= @deploy_to %>/shared/tmp/puma.state"
```

### puma.service.erb

```erb
[Unit]
Description=Puma HTTP Server for <%= @app_name %>
After=network.target

[Service]
Type=simple
User=<%= @user %>
WorkingDirectory=<%= @deploy_to %>/releases/current
ExecStart=/usr/local/bin/bundle exec puma -C <%= @deploy_to %>/shared/config/puma.rb
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### env.erb

```erb
RAILS_ENV=<%= @environment %>
SECRET_KEY_BASE=<%= @secret_key_base %>
PORT=<%= @port %>
```

## Running

```bash
itamae ssh -j nodes/app01.json -h app01.example.com cookbooks/ruby-app/default.rb
```
