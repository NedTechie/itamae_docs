---
title: "✅ Best Practices"
---

Itamae does not force a specific project structure. These are recommended patterns that work well as projects grow.

## 📁 Directory Structure

Organize recipes into **cookbooks** (software-specific) and **roles** (server purpose):

```
.
├── Gemfile
├── cookbooks/
│   ├── nginx/
│   │   ├── default.rb
│   │   ├── files/
│   │   │   └── etc/nginx/conf.d/
│   │   │       └── static.conf
│   │   └── templates/
│   │       └── etc/nginx/conf.d/
│   │           └── dynamic.conf.erb
│   ├── ruby/
│   │   └── default.rb
│   └── postgresql/
│       ├── default.rb
│       └── templates/
│           └── etc/postgresql/
│               └── pg_hba.conf.erb
├── roles/
│   ├── web.rb
│   └── db.rb
└── nodes/
    ├── web01.json
    └── db01.json
```

- **Cookbook** -- a collection of recipes managing specific software (nginx, PostgreSQL, Ruby)
- **Role** -- represents a server's purpose (web, database, worker)

### 🎭 Role file

```ruby
# roles/web.rb
include_recipe '../cookbooks/nginx'
include_recipe '../cookbooks/ruby'
```

### ▶️ Provisioning

```bash
itamae local roles/web.rb
itamae ssh --host web01 -j nodes/web01.json roles/web.rb
```

## 🔍 Use `:auto` Source

Let Itamae find source files automatically instead of specifying explicit paths:

```ruby
# Itamae finds files/etc/nginx/conf.d/static.conf automatically
remote_file '/etc/nginx/conf.d/static.conf'

# Itamae finds templates/etc/nginx/conf.d/dynamic.conf.erb automatically
template '/etc/nginx/conf.d/dynamic.conf'
```

### Search Order for `remote_file`

For path `/foo/bar/baz.conf`:

1. `files/foo/bar/baz.conf` (recommended)
2. `files/bar/baz.conf`
3. `files/baz.conf`

### Search Order for `template`

For path `/foo/bar/baz.conf`:

1. `templates/foo/bar/baz.conf.erb` (recommended)
2. `templates/foo/bar/baz.conf`
3. `templates/bar/baz.conf.erb`
4. `templates/bar/baz.conf`
5. `templates/baz.conf.erb`
6. `templates/baz.conf`

## ✔️ Validate Node Attributes

Add validation at the top of cookbooks to catch misconfiguration early:

```ruby
# cookbooks/nginx/default.rb
node.validate! do
  {
    nginx: {
      user: string,
      worker_processes: optional(integer),
      sites: array_of({
        server_name: string,
        root: string,
        allowed_ips: array_of(string),
      }),
    },
  }
end

package 'nginx'
# ...
```

## 🛡️ Use Guards for Idempotency

Make resources idempotent with `only_if` and `not_if`:

```ruby
execute 'initialize database' do
  command '/opt/app/bin/db-init'
  not_if 'test -f /opt/app/.db-initialized'
end
```

## 🔔 Use Notifications

Avoid unconditional service restarts. Instead, notify services when their configuration changes:

```ruby
# Bad: always restarts
service 'nginx' do
  action :restart
end

# Good: only restarts when config changes
service 'nginx' do
  action [:enable, :start]
end

template '/etc/nginx/nginx.conf' do
  source 'nginx.conf.erb'
  notifies :restart, 'service[nginx]'
end
```

## 🔎 Dry Run First

Always preview changes before applying:

```bash
itamae local --dry-run roles/web.rb
itamae local roles/web.rb
```

## 🚦 Use Detailed Exit Codes in CI

In CI/CD pipelines, use `--detailed_exitcode` to distinguish between "no changes" and "changes applied":

```bash
itamae local --detailed_exitcode roles/web.rb
# Exit 0: no changes needed
# Exit 1: failure
# Exit 2: changes applied successfully
```

## 📐 Keep Recipes Small

Split large recipes into focused cookbooks. Each cookbook should manage one piece of software or concern.

## 🌍 Use Node Attributes for Environment Differences

Avoid conditionals in recipes. Instead, parameterize differences via node attributes:

```ruby
# Good: data-driven
template '/etc/app.conf' do
  variables(port: node[:app][:port])
end
```

```json
// nodes/staging.json
{"app": {"port": 3000}}

// nodes/production.json
{"app": {"port": 80}}
```
