---
title: "Example: Let's Encrypt SSL"
---

# Let's Encrypt SSL Certificates

Automate TLS certificate provisioning with certbot, including Nginx integration and auto-renewal via cron.

## Directory Structure

```
cookbooks/
  letsencrypt/
    default.rb
    templates/
      certbot-renew.cron.erb
      ssl-params.conf.erb
nodes/
  web01.json
```

## Node Attributes

```json
{
  "letsencrypt": {
    "email": "admin@example.com",
    "domains": ["example.com", "www.example.com"],
    "webroot_path": "/var/www/certbot",
    "ssl_dir": "/etc/letsencrypt",
    "renew_hook": "systemctl reload nginx",
    "key_size": 4096
  }
}
```

## Recipe

```ruby
# cookbooks/letsencrypt/default.rb

le = node['letsencrypt']
primary_domain = le['domains'].first

package 'certbot' do
  action :install
end

package 'python3-certbot-nginx' do
  action :install
end

directory le['webroot_path'] do
  owner 'www-data'
  group 'www-data'
  mode '0755'
end

directory '/etc/nginx/snippets' do
  owner 'root'
  group 'root'
  mode '0755'
end

# SSL hardening parameters shared across vhosts
template '/etc/nginx/snippets/ssl-params.conf' do
  source 'templates/ssl-params.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    ssl_dir: le['ssl_dir']
  )
  notifies :reload, 'service[nginx]'
end

# Initial certificate request
execute "certbot-initial-#{primary_domain}" do
  command "certbot certonly --nginx -d #{le['domains'].join(' -d ')} --non-interactive --agree-tos --email #{le['email']} --rsa-key-size #{le['key_size']}"
  not_if "test -d #{le['ssl_dir']}/live/#{primary_domain}"
end

# Auto-renewal cron
template '/etc/cron.d/certbot-renew' do
  source 'templates/certbot-renew.cron.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    renew_hook: le['renew_hook']
  )
end

# DH parameters for forward secrecy
execute 'generate-dhparam' do
  command "openssl dhparam -out #{le['ssl_dir']}/dhparam.pem 2048"
  not_if "test -f #{le['ssl_dir']}/dhparam.pem"
end

service 'nginx' do
  action [:enable, :start]
end
```

## Templates

### ssl-params.conf.erb

```erb
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers on;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
ssl_session_timeout 1d;
ssl_session_cache shared:SSL:10m;
ssl_session_tickets off;
ssl_dhparam <%= @ssl_dir %>/dhparam.pem;
ssl_stapling on;
ssl_stapling_verify on;
add_header Strict-Transport-Security "max-age=63072000" always;
```

### certbot-renew.cron.erb

```erb
# Renew certificates twice daily
0 3,15 * * * root certbot renew --quiet --deploy-hook "<%= @renew_hook %>"
```

## Running

```bash
itamae ssh -j nodes/web01.json -h web01.example.com cookbooks/letsencrypt/default.rb
```
