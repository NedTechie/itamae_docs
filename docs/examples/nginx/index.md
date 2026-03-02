---
title: "Example: Nginx Web Server"
---

# Nginx Web Server

Install and configure Nginx with virtual hosts, SSL-ready configuration, and log rotation.

## Directory Structure

```
cookbooks/
  nginx/
    default.rb
    templates/
      nginx.conf.erb
      vhost.conf.erb
    files/
      logrotate-nginx
nodes/
  web01.json
```

## Node Attributes

```json
{
  "nginx": {
    "worker_processes": 4,
    "worker_connections": 1024,
    "server_name": "app.example.com",
    "root": "/var/www/app/current/public",
    "upstream_port": 3000,
    "ssl_certificate": "/etc/ssl/certs/app.pem",
    "ssl_certificate_key": "/etc/ssl/private/app.key"
  }
}
```

## Recipe

```ruby
# cookbooks/nginx/default.rb

package 'nginx' do
  action :install
end

directory '/etc/nginx/sites-available' do
  owner 'root'
  group 'root'
  mode '0755'
end

directory '/etc/nginx/sites-enabled' do
  owner 'root'
  group 'root'
  mode '0755'
end

directory '/var/log/nginx' do
  owner 'www-data'
  group 'adm'
  mode '0750'
end

template '/etc/nginx/nginx.conf' do
  source 'templates/nginx.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    worker_processes: node['nginx']['worker_processes'],
    worker_connections: node['nginx']['worker_connections']
  )
  notifies :reload, 'service[nginx]'
end

template '/etc/nginx/sites-available/app.conf' do
  source 'templates/vhost.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    server_name: node['nginx']['server_name'],
    root: node['nginx']['root'],
    upstream_port: node['nginx']['upstream_port'],
    ssl_certificate: node['nginx']['ssl_certificate'],
    ssl_certificate_key: node['nginx']['ssl_certificate_key']
  )
  notifies :reload, 'service[nginx]'
end

link '/etc/nginx/sites-enabled/app.conf' do
  to '/etc/nginx/sites-available/app.conf'
  notifies :reload, 'service[nginx]'
end

execute 'remove default site' do
  command 'rm -f /etc/nginx/sites-enabled/default'
  only_if 'test -f /etc/nginx/sites-enabled/default'
end

service 'nginx' do
  action [:enable, :start]
end
```

## Templates

### nginx.conf.erb

```erb
user www-data;
worker_processes <%= @worker_processes %>;
pid /run/nginx.pid;

events {
    worker_connections <%= @worker_connections %>;
}

http {
    sendfile on;
    tcp_nopush on;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    gzip on;

    include /etc/nginx/sites-enabled/*;
}
```

### vhost.conf.erb

```erb
upstream app {
    server 127.0.0.1:<%= @upstream_port %>;
}

server {
    listen 443 ssl;
    server_name <%= @server_name %>;

    ssl_certificate     <%= @ssl_certificate %>;
    ssl_certificate_key <%= @ssl_certificate_key %>;

    root <%= @root %>;

    location / {
        try_files $uri @app;
    }

    location @app {
        proxy_pass http://app;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Running

```bash
itamae ssh -j nodes/web01.json -h web01.example.com cookbooks/nginx/default.rb
```
