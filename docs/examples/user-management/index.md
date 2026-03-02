---
title: "Example: User Management"
---

# User Management

Manage system users, groups, SSH authorized keys, sudoers configuration, and home directory setup.

## Directory Structure

```
cookbooks/
  users/
    default.rb
    templates/
      sudoers.erb
nodes/
  base.json
```

## Node Attributes

```json
{
  "users": {
    "admins": [
      {
        "name": "alice",
        "uid": 2001,
        "shell": "/bin/bash",
        "ssh_key": "ssh-ed25519 AAAA... alice@example.com"
      },
      {
        "name": "bob",
        "uid": 2002,
        "shell": "/bin/zsh",
        "ssh_key": "ssh-ed25519 AAAA... bob@example.com"
      }
    ],
    "deployers": [
      {
        "name": "deploy",
        "uid": 3001,
        "shell": "/bin/bash"
      }
    ],
    "admin_group_gid": 2000,
    "deploy_group_gid": 3000
  }
}
```

## Recipe

```ruby
# cookbooks/users/default.rb

group 'admins' do
  gid node['users']['admin_group_gid']
end

group 'deployers' do
  gid node['users']['deploy_group_gid']
end

node['users']['admins'].each do |admin|
  user admin['name'] do
    uid admin['uid']
    gid node['users']['admin_group_gid']
    home "/home/#{admin['name']}"
    shell admin['shell']
    create_home true
  end

  directory "/home/#{admin['name']}/.ssh" do
    owner admin['name']
    group admin['name']
    mode '0700'
  end

  file "/home/#{admin['name']}/.ssh/authorized_keys" do
    content admin['ssh_key']
    owner admin['name']
    group admin['name']
    mode '0600'
  end
end

node['users']['deployers'].each do |deployer|
  user deployer['name'] do
    uid deployer['uid']
    gid node['users']['deploy_group_gid']
    home "/home/#{deployer['name']}"
    shell deployer['shell']
    create_home true
  end

  directory "/home/#{deployer['name']}/.ssh" do
    owner deployer['name']
    group deployer['name']
    mode '0700'
  end
end

template '/etc/sudoers.d/admins' do
  source 'templates/sudoers.erb'
  owner 'root'
  group 'root'
  mode '0440'
  variables(
    admin_group: 'admins'
  )
end

execute 'validate-sudoers' do
  command 'visudo -cf /etc/sudoers.d/admins'
  only_if 'test -f /etc/sudoers.d/admins'
end
```

## Templates

### sudoers.erb

```erb
# Managed by Itamae
%<%= @admin_group %> ALL=(ALL:ALL) NOPASSWD:ALL
```

## Running

```bash
itamae ssh -j nodes/base.json -h server01.example.com cookbooks/users/default.rb
```
