---
title: "Example: Security Hardening"
---

# Security Hardening

SSH hardening, firewall rules (UFW), fail2ban, and audit logging configuration.

## Directory Structure

```
cookbooks/
  security/
    default.rb
    templates/
      sshd_config.erb
      jail.local.erb
      audit.rules.erb
nodes/
  secure01.json
```

## Node Attributes

```json
{
  "security": {
    "ssh_port": 2222,
    "permit_root_login": "no",
    "password_authentication": "no",
    "allowed_users": ["alice", "bob", "deploy"],
    "ufw_allowed_ports": [2222, 80, 443],
    "fail2ban_maxretry": 3,
    "fail2ban_bantime": 3600,
    "fail2ban_findtime": 600
  }
}
```

## Recipe

```ruby
# cookbooks/security/default.rb

sec = node['security']

# --- SSH Hardening ---

template '/etc/ssh/sshd_config' do
  source 'templates/sshd_config.erb'
  owner 'root'
  group 'root'
  mode '0600'
  variables(
    port: sec['ssh_port'],
    permit_root_login: sec['permit_root_login'],
    password_authentication: sec['password_authentication'],
    allowed_users: sec['allowed_users']
  )
  notifies :restart, 'service[sshd]'
end

service 'sshd' do
  action [:enable, :start]
end

# --- Firewall (UFW) ---

package 'ufw' do
  action :install
end

execute 'ufw-default-deny' do
  command 'ufw default deny incoming'
  not_if 'ufw status | grep -q "Default: deny (incoming)"'
end

sec['ufw_allowed_ports'].each do |port|
  execute "ufw-allow-#{port}" do
    command "ufw allow #{port}/tcp"
    not_if "ufw status | grep -q '#{port}/tcp'"
  end
end

execute 'ufw-enable' do
  command 'ufw --force enable'
  not_if 'ufw status | grep -q "Status: active"'
end

# --- Fail2ban ---

package 'fail2ban' do
  action :install
end

template '/etc/fail2ban/jail.local' do
  source 'templates/jail.local.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    ssh_port: sec['ssh_port'],
    maxretry: sec['fail2ban_maxretry'],
    bantime: sec['fail2ban_bantime'],
    findtime: sec['fail2ban_findtime']
  )
  notifies :restart, 'service[fail2ban]'
end

service 'fail2ban' do
  action [:enable, :start]
end

# --- Audit Logging ---

package 'auditd' do
  action :install
end

directory '/etc/audit/rules.d' do
  owner 'root'
  group 'root'
  mode '0750'
end

template '/etc/audit/rules.d/itamae.rules' do
  source 'templates/audit.rules.erb'
  owner 'root'
  group 'root'
  mode '0640'
  notifies :restart, 'service[auditd]'
end

service 'auditd' do
  action [:enable, :start]
end
```

## Templates

### sshd_config.erb

```erb
Port <%= @port %>
PermitRootLogin <%= @permit_root_login %>
PasswordAuthentication <%= @password_authentication %>
AllowUsers <%= @allowed_users.join(' ') %>
PubkeyAuthentication yes
X11Forwarding no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
```

### jail.local.erb

```erb
[DEFAULT]
bantime = <%= @bantime %>
findtime = <%= @findtime %>
maxretry = <%= @maxretry %>

[sshd]
enabled = true
port = <%= @ssh_port %>
filter = sshd
logpath = /var/log/auth.log
```

### audit.rules.erb

```erb
# Monitor authentication logs
-w /var/log/auth.log -p wa -k auth_log
# Monitor sudoers
-w /etc/sudoers -p wa -k sudoers
-w /etc/sudoers.d/ -p wa -k sudoers
# Monitor SSH config
-w /etc/ssh/sshd_config -p wa -k sshd_config
```

## Running

```bash
itamae ssh -j nodes/secure01.json -h server01.example.com cookbooks/security/default.rb
```
