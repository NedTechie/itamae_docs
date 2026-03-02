---
title: "Example: Multi-Tier Application"
---

# Multi-Tier Application

Compose roles from individual cookbooks to provision a complete web + application + database stack.

## Directory Structure

```
cookbooks/
  nginx/
    default.rb
  ruby-app/
    default.rb
  postgresql/
    default.rb
  docker/
    default.rb
  users/
    default.rb
  monitoring/
    default.rb
  security/
    default.rb
roles/
  base.rb
  web.rb
  app.rb
  db.rb
nodes/
  web01.json
  app01.json
  db01.json
```

## Role Recipes

### roles/base.rb

Common configuration applied to every server: security hardening, user management, and monitoring.

```ruby
# roles/base.rb

include_recipe '../cookbooks/security/default.rb'
include_recipe '../cookbooks/users/default.rb'
include_recipe '../cookbooks/monitoring/default.rb'
```

### roles/web.rb

Web tier: base configuration plus Nginx.

```ruby
# roles/web.rb

include_recipe './base.rb'
include_recipe '../cookbooks/nginx/default.rb'
```

### roles/app.rb

Application tier: base configuration plus the Ruby app deployment.

```ruby
# roles/app.rb

include_recipe './base.rb'
include_recipe '../cookbooks/ruby-app/default.rb'
```

### roles/db.rb

Database tier: base configuration plus PostgreSQL.

```ruby
# roles/db.rb

include_recipe './base.rb'
include_recipe '../cookbooks/postgresql/default.rb'
```

## Node Attributes

Each tier gets its own node JSON that merges base settings with tier-specific ones.

### nodes/web01.json

```json
{
  "security": {
    "ssh_port": 2222,
    "permit_root_login": "no",
    "password_authentication": "no",
    "allowed_users": ["alice", "deploy"],
    "ufw_allowed_ports": [2222, 80, 443],
    "fail2ban_maxretry": 3,
    "fail2ban_bantime": 3600,
    "fail2ban_findtime": 600
  },
  "users": {
    "admins": [
      { "name": "alice", "uid": 2001, "shell": "/bin/bash", "ssh_key": "ssh-ed25519 AAAA..." }
    ],
    "deployers": [{ "name": "deploy", "uid": 3001, "shell": "/bin/bash" }],
    "admin_group_gid": 2000,
    "deploy_group_gid": 3000
  },
  "monitoring": {
    "node_exporter_version": "1.7.0",
    "node_exporter_port": 9100,
    "node_exporter_user": "node_exporter",
    "node_exporter_uid": 9100,
    "textfile_dir": "/var/lib/node_exporter/textfile",
    "health_check_url": "https://health.example.com/ping",
    "alert_email": "ops@example.com"
  },
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

### nodes/app01.json

```json
{
  "security": { "...": "same base security settings" },
  "users": { "...": "same base user settings" },
  "monitoring": { "...": "same base monitoring settings" },
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

### nodes/db01.json

```json
{
  "security": { "...": "same base security settings" },
  "users": { "...": "same base user settings" },
  "monitoring": { "...": "same base monitoring settings" },
  "postgresql": {
    "version": "15",
    "data_dir": "/var/lib/postgresql/15/main",
    "max_connections": 200,
    "shared_buffers": "256MB",
    "effective_cache_size": "1GB",
    "db_name": "myapp_production",
    "db_user": "myapp",
    "db_password": "secret",
    "backup_dir": "/var/backups/postgresql",
    "backup_retention_days": 7
  }
}
```

## Running

Provision each tier by pointing Itamae at the role recipe and the appropriate node file:

```bash
# Web tier
itamae ssh -j nodes/web01.json -h web01.example.com roles/web.rb

# App tier
itamae ssh -j nodes/app01.json -h app01.example.com roles/app.rb

# Database tier
itamae ssh -j nodes/db01.json -h db01.example.com roles/db.rb
```

## Scaling

To add more servers, create additional node JSON files and run the corresponding role:

```bash
# Add a second web server
itamae ssh -j nodes/web02.json -h web02.example.com roles/web.rb

# Add a second app server
itamae ssh -j nodes/app02.json -h app02.example.com roles/app.rb
```

The key benefit of role-based composition is that each cookbook is maintained independently while roles combine them for specific server functions.
