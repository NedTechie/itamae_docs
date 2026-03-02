---
title: Real-World Examples
---

# Real-World Examples

Production-style Itamae recipes for common infrastructure tasks. Each example includes a complete directory structure, node attributes, recipe code, and templates.

## Examples

| Example | Description | Key Resources |
|---------|-------------|---------------|
| [Nginx Web Server]({{ '/docs/examples/nginx/' | relative_url }}) | Install and configure Nginx with virtual hosts | package, service, template, directory, execute, link |
| [PostgreSQL Database]({{ '/docs/examples/postgresql/' | relative_url }}) | Set up PostgreSQL with users, databases, and tuning | package, service, template, execute, user, group, directory |
| [Ruby Application]({{ '/docs/examples/ruby-app/' | relative_url }}) | Deploy a Ruby app with Puma and systemd | user, directory, git, gem_package, execute, template, service, link |
| [Docker Host]({{ '/docs/examples/docker-host/' | relative_url }}) | Provision a Docker host with daemon configuration | package, execute, template, group, service, file |
| [User Management]({{ '/docs/examples/user-management/' | relative_url }}) | Manage system users, groups, SSH keys, and sudoers | user, group, directory, file, template, execute |
| [Monitoring Stack]({{ '/docs/examples/monitoring/' | relative_url }}) | Deploy a monitoring agent with health checks | user, http_request, template, service, directory, file |
| [Security Hardening]({{ '/docs/examples/security/' | relative_url }}) | SSH hardening, firewall rules, and audit logging | template, package, service, execute, file, directory |
| [Redis Cache]({{ '/docs/examples/redis/' | relative_url }}) | In-memory data store with persistence and kernel tuning | package, service, template, user, group, directory, execute |
| [Let's Encrypt SSL]({{ '/docs/examples/letsencrypt/' | relative_url }}) | TLS certificates with certbot and auto-renewal | package, execute, template, directory, service |
| [Log Management]({{ '/docs/examples/log-management/' | relative_url }}) | Centralized rsyslog forwarding and logrotate | package, template, service, directory |
| [MySQL Database]({{ '/docs/examples/mysql/' | relative_url }}) | MySQL server with users, backups, and tuning | package, service, template, execute, user, group, directory |
| [HAProxy Load Balancer]({{ '/docs/examples/haproxy/' | relative_url }}) | Reverse proxy with health checks and stats | package, service, template, directory, file, execute |
| [Jenkins CI]({{ '/docs/examples/jenkins-ci/' | relative_url }}) | CI/CD server with Java, plugins, and Nginx proxy | package, service, template, directory, execute, link |
| [Multi-Tier Application]({{ '/docs/examples/multi-tier/' | relative_url }}) | Compose roles for a full web + app + db stack | Roles combining all the above |

## How to Use These Examples

1. **Copy the directory structure** into your Itamae project
2. **Customize node attributes** in your JSON files for each host
3. **Run with Itamae** targeting your server:

```bash
# Local execution
itamae local -j nodes/web01.json cookbooks/nginx/default.rb

# Remote via SSH
itamae ssh -j nodes/web01.json -h web01.example.com cookbooks/nginx/default.rb
```

See the [Getting Started guide]({{ '/docs/getting-started/' | relative_url }}) for installation and the [CLI Reference]({{ '/docs/cli-reference/' | relative_url }}) for all options.
