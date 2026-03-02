---
title: Guides
---

In-depth guides for working with Itamae.

## Core Concepts

| Guide | Description |
|-------|-------------|
| [Writing Recipes]({{ '/docs/recipes/' | relative_url }}) | Recipe DSL, including recipes, guards, node access |
| [Node Attributes]({{ '/docs/node-attributes/' | relative_url }}) | Loading, accessing, and validating host-specific data |
| [Definitions]({{ '/docs/definitions/' | relative_url }}) | Grouping resources into reusable parameterized blocks |
| [Notifications]({{ '/docs/notifications/' | relative_url }}) | Triggering actions between resources with notifies/subscribes |
| [run_command]({{ '/docs/run-command/' | relative_url }}) | Executing commands and capturing output in recipes |

## Infrastructure

| Guide | Description |
|-------|-------------|
| [Backends]({{ '/docs/backends/' | relative_url }}) | Local, SSH, Docker, and Jail execution |
| [CLI Reference]({{ '/docs/cli-reference/' | relative_url }}) | All commands, options, and exit codes |
| [Handlers]({{ '/docs/handlers/' | relative_url }}) | Event handlers for logging and monitoring |

## Extending Itamae

| Guide | Description |
|-------|-------------|
| [Plugins]({{ '/docs/plugins/' | relative_url }}) | Creating and using recipe and resource plugins |
| [Best Practices]({{ '/docs/best-practices/' | relative_url }}) | Recommended project structure and patterns |

## Quick Reference

### Resource Cheat Sheet

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

### Common Patterns

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
