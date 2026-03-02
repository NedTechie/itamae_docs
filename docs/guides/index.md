---
title: "📚 Guides"
---

In-depth guides for working with Itamae.

## 🧠 Core Concepts

| Guide | Description |
|-------|-------------|
| [Writing Recipes]({{ '/docs/recipes/' | relative_url }}) | Recipe DSL, including recipes, guards, node access |
| [Node Attributes]({{ '/docs/node-attributes/' | relative_url }}) | Loading, accessing, and validating host-specific data |
| [Definitions]({{ '/docs/definitions/' | relative_url }}) | Grouping resources into reusable parameterized blocks |
| [Notifications]({{ '/docs/notifications/' | relative_url }}) | Triggering actions between resources with notifies/subscribes |
| [run_command]({{ '/docs/run-command/' | relative_url }}) | Executing commands and capturing output in recipes |

## 🏗️ Infrastructure

| Guide | Description |
|-------|-------------|
| [Backends]({{ '/docs/backends/' | relative_url }}) | Local, SSH, Docker, and Jail execution |
| [CLI Reference]({{ '/docs/cli-reference/' | relative_url }}) | All commands, options, and exit codes |
| [Handlers]({{ '/docs/handlers/' | relative_url }}) | Event handlers for logging and monitoring |

## 🔌 Extending Itamae

| Guide | Description |
|-------|-------------|
| [Plugins]({{ '/docs/plugins/' | relative_url }}) | Creating and using recipe and resource plugins |
| [Best Practices]({{ '/docs/best-practices/' | relative_url }}) | Recommended project structure and patterns |

## 🌍 Real-World Examples

| Example | Description |
|---------|-------------|
| [Nginx Web Server]({{ '/docs/examples/nginx/' | relative_url }}) | Install and configure Nginx with virtual hosts and SSL |
| [PostgreSQL Database]({{ '/docs/examples/postgresql/' | relative_url }}) | Set up PostgreSQL with users, databases, and backups |
| [Ruby App Deployment]({{ '/docs/examples/ruby-app/' | relative_url }}) | Deploy a Ruby app with Puma and systemd |
| [Docker Host]({{ '/docs/examples/docker-host/' | relative_url }}) | Provision a Docker host with daemon configuration |
| [User Management]({{ '/docs/examples/user-management/' | relative_url }}) | Manage users, groups, SSH keys, and sudoers |
| [Monitoring Stack]({{ '/docs/examples/monitoring/' | relative_url }}) | Deploy monitoring agents with health checks |
| [Security Hardening]({{ '/docs/examples/security/' | relative_url }}) | SSH hardening, firewall rules, and audit logging |
| [Redis Cache]({{ '/docs/examples/redis/' | relative_url }}) | In-memory data store with persistence and kernel tuning |
| [Let's Encrypt SSL]({{ '/docs/examples/letsencrypt/' | relative_url }}) | TLS certificates with certbot and auto-renewal |
| [Log Management]({{ '/docs/examples/log-management/' | relative_url }}) | Centralized rsyslog forwarding and logrotate |
| [MySQL Database]({{ '/docs/examples/mysql/' | relative_url }}) | MySQL server with users, backups, and tuning |
| [HAProxy Load Balancer]({{ '/docs/examples/haproxy/' | relative_url }}) | Reverse proxy with health checks and stats dashboard |
| [Jenkins CI]({{ '/docs/examples/jenkins-ci/' | relative_url }}) | CI/CD server with Java, plugins, and Nginx proxy |
| [Multi-Tier Application]({{ '/docs/examples/multi-tier/' | relative_url }}) | Compose roles for a full web + app + db stack |

See [all examples]({{ '/docs/examples/' | relative_url }}) for complete recipes with directory structures, node attributes, and templates.

## ❓ FAQ

Common questions and answers about Itamae -- see the full [FAQ page]({{ '/docs/faq/' | relative_url }}).

## ⚡ Quick Reference

### 📋 Resource Cheat Sheet

```ruby
# Files & directories
file '/path'          do content 'data'; mode '0644' end
directory '/path'     do mode '0755'; owner 'user' end
template '/path'      do source 'tmpl.erb'; variables(k: 'v') end
remote_file '/path'   do source 'files/src'; mode '0644' end
link '/path'          do to '/target' end

# Packages & services
package 'name'        do version '1.0' end
gem_package 'name'    do version '1.0' end
service 'name'        do action [:enable, :start] end

# Commands
execute 'name'        do command 'echo hi'; not_if 'test -f /done' end

# Users & groups
user 'name'           do uid 1000; home '/home/name'; shell '/bin/bash' end
group 'name'          do gid 1000 end

# Other
git '/path'           do repository 'url'; revision 'main' end
http_request '/path'  do url 'https://example.com/file' end
remote_directory '/p' do source 'dir' end
local_ruby_block 'n'  do block { puts 'hi' } end
```

### 🔄 Common Patterns

```ruby
# Notify service on config change
template '/etc/app.conf' do
  source 'app.conf.erb'
  notifies :restart, 'service[app]'
end

# Conditional execution
execute 'setup' do
  command '/opt/bin/setup'
  not_if 'test -f /opt/.done'
end

# Multiple node files
# itamae local -j base.json -j env.json roles/web.rb
```
