---
title: "❓ FAQ"
---

Frequently asked questions about using Itamae.

---

## 📦 Packages

### How do I check if a package is installed?

Itamae handles this automatically. The `package` resource checks the current state before acting -- if the package is already installed, it does nothing:

```ruby
package 'nginx' do
  action :install
end
```

Under the hood, Itamae uses [Specinfra](https://github.com/mizzy/specinfra) to run the right command for your OS:

| OS | Check command |
|----|---------------|
| Debian/Ubuntu | `dpkg-query -f '${Status}' -W nginx \| grep -E '^(install\|hold) ok installed$'` |
| RHEL/CentOS/Fedora | `rpm -q nginx` |
| Alpine | `apk info -qe nginx` |
| SUSE/openSUSE | `rpm -q nginx` |

> 💡 You never need to write these commands yourself -- Itamae detects your OS and picks the right one automatically.

### How do I install a specific version?

```ruby
package 'nginx' do
  version '1.24.0-1'
end
```

Itamae checks both the package name **and** version. If the package is installed but at a different version, it will install the requested version.

### How do I pass options to the package manager?

```ruby
package 'nginx' do
  options '--force-yes'  # passed directly to apt-get, yum, etc.
end
```

### How do I remove a package?

```ruby
package 'nginx' do
  action :remove
end
```

### How do I skip a package install conditionally?

Use guards to run shell commands on the target. A zero exit status means the condition is true:

```ruby
# Only install if a certain file exists
package 'monitoring-agent' do
  only_if 'test -f /etc/enable-monitoring'
end

# Don't install if already available via another method
package 'node' do
  not_if 'which node'
end
```

---

## 🔄 Services

### Why doesn't my service start?

The `service` resource default action is `:nothing` -- it won't start unless you explicitly tell it to:

```ruby
# This does nothing by default!
service 'nginx'

# Correct: explicitly enable and start
service 'nginx' do
  action [:enable, :start]
end
```

### How do I restart a service only when config changes?

Use [notifications]({{ '/docs/notifications/' | relative_url }}). The service only restarts if the template actually changes:

```ruby
service 'nginx' do
  action [:enable, :start]
end

template '/etc/nginx/nginx.conf' do
  source 'nginx.conf.erb'
  notifies :restart, 'service[nginx]'
end
```

### What's the difference between `:restart` and `:reload`?

- `:restart` -- stops and starts the service (brief downtime)
- `:reload` -- sends a signal to re-read config without stopping (zero downtime, but not all services support it)

```ruby
template '/etc/nginx/conf.d/site.conf' do
  source 'site.conf.erb'
  notifies :reload, 'service[nginx]'  # zero-downtime config reload
end
```

---

## 📄 Files & Templates

### What's the difference between `file`, `remote_file`, and `template`?

| Resource | Source | Use case |
|----------|--------|----------|
| `file` | Inline `content` string | Short, static content |
| `remote_file` | Local file on the Itamae machine | Static files (binaries, configs without variables) |
| `template` | ERB template on the Itamae machine | Dynamic configs with variables |

```ruby
# Inline content
file '/etc/motd' do
  content "Welcome to #{node[:hostname]}\n"
end

# Copy a static file
remote_file '/usr/local/bin/tool' do
  source 'files/tool'
  mode '0755'
end

# Render a template with variables
template '/etc/app.conf' do
  source 'templates/app.conf.erb'
  variables(port: node[:app][:port])
end
```

### How does `:auto` source work?

If you omit `source`, Itamae searches for files relative to the recipe file:

```ruby
# Itamae looks for files/etc/nginx/nginx.conf
remote_file '/etc/nginx/nginx.conf'

# Itamae looks for templates/etc/app.conf.erb
template '/etc/app.conf'
```

**Search order for `remote_file`** (path `/foo/bar/baz.conf`):
1. `files/foo/bar/baz.conf` (recommended)
2. `files/bar/baz.conf`
3. `files/baz.conf`

**Search order for `template`** (path `/foo/bar/baz.conf`):
1. `templates/foo/bar/baz.conf.erb` (recommended)
2. `templates/foo/bar/baz.conf`
3. `templates/bar/baz.conf.erb`
4. `templates/bar/baz.conf`
5. `templates/baz.conf.erb`
6. `templates/baz.conf`

### How do I hide sensitive file content in logs?

Use the `sensitive` attribute to suppress diffs in output:

```ruby
file '/etc/app/secret.key' do
  content node[:app][:secret_key]
  mode '0600'
  sensitive true
end
```

---

## 🔍 Dry Run

### Does dry-run actually change anything?

No. Dry-run (`--dry-run` or `-n`) skips all `action_*` methods, so no files are written, no packages installed, and no services restarted. It only **shows** what would change.

```bash
itamae local --dry-run recipe.rb
```

> ⚠️ **Exception:** The `http_request` resource makes a real HTTP request during dry-run (to fetch the response body for diff comparison). The response is not saved to disk, but the request does hit the remote server.

See the full [Dry-Run Mode guide]({{ '/docs/dry-run/' | relative_url }}) for per-resource behavior details.

### Can I use dry-run in CI/CD?

Yes. Combine `--dry-run` with `--detailed_exitcode` to detect drift:

```bash
itamae local --dry-run --detailed_exitcode recipe.rb
# Exit 0: no changes needed
# Exit 2: changes would be made (drift detected)
```

---

## 🛡️ Guards & Idempotency

### How do `only_if` and `not_if` work?

Guards run shell commands **on the target host**. The resource is skipped based on the exit status:

- `only_if` -- execute the resource only if the command exits `0` (success)
- `not_if` -- skip the resource if the command exits `0` (success)

```ruby
execute 'initialize database' do
  command '/opt/app/bin/db-init'
  not_if 'test -f /opt/app/.db-initialized'
end
```

> 💡 Guards run even in dry-run mode -- they execute real commands to determine the current state.

### How do I make `execute` resources idempotent?

Always pair `execute` with a guard so it doesn't re-run on every converge:

```ruby
# Bad: runs every time
execute 'create database' do
  command 'createdb myapp'
end

# Good: only runs if the database doesn't exist
execute 'create database' do
  command 'createdb myapp'
  not_if 'psql -lqt | grep -qw myapp'
end
```

---

## 🔔 Notifications

### What's the difference between `:delayed` and `:immediately`?

| Timing | When it runs | Deduplication |
|--------|-------------|---------------|
| `:delayed` (default) | After the entire recipe completes | Yes -- runs once even if notified multiple times |
| `:immediately` | Right after the notifying resource | No -- runs each time it's notified |

```ruby
# Delayed (default): nginx restarts once at the end
template '/etc/nginx/nginx.conf' do
  notifies :restart, 'service[nginx]'
end

template '/etc/nginx/conf.d/site.conf' do
  notifies :restart, 'service[nginx]'
end

# Immediate: runs right away before continuing
package 'nginx' do
  notifies :start, 'service[nginx]', :immediately
end
```

### What's the difference between `notifies` and `subscribes`?

They do the same thing from opposite directions:

```ruby
# notifies: "when I change, tell nginx to restart"
template '/etc/nginx/nginx.conf' do
  notifies :restart, 'service[nginx]'
end

# subscribes: "when nginx.conf changes, I should restart"
service 'nginx' do
  action :nothing
  subscribes :restart, 'template[/etc/nginx/nginx.conf]'
end
```

---

## 📋 Node Attributes

### How do I access node attributes in a template?

Use the `node` object directly in ERB:

```erb
server_name = <%= node[:hostname] %>
listen_port = <%= node[:app][:port] %>
workers = <%= node[:app][:workers] || 4 %>
```

### Can I use symbols, strings, or methods to access attributes?

Yes, all three work thanks to `Hashie::Mash`:

```ruby
node[:app][:port]      # symbol keys
node['app']['port']    # string keys
node.app.port          # method syntax
```

### How do I merge multiple attribute files?

Later files take precedence in a deep merge:

```bash
itamae local -j base.json -j env.json -y overrides.yml recipe.rb
```

---

## 🖥️ Backends

### How do I run recipes on a remote server?

Use the SSH backend:

```bash
itamae ssh --host web01.example.com --user deploy --key ~/.ssh/id_rsa recipe.rb
```

### How do I connect to a Vagrant VM?

```bash
itamae ssh --vagrant --host default recipe.rb
```

Itamae reads the Vagrant SSH config automatically.

### How do I build Docker images with Itamae?

```bash
itamae docker --image ubuntu:22.04 --tag myapp:latest recipe.rb
```

Itamae creates a container from the base image, applies recipes inside it, then commits the result as a new image.

---

## 🧩 Definitions & Plugins

### When should I use a definition vs. a plugin?

| | Definitions | Plugins |
|-|-------------|---------|
| **Scope** | Single project | Shared across projects |
| **Distribution** | Inline in recipes | Published as a gem |
| **Complexity** | Simple grouping | Full Ruby class |

Use definitions for project-specific abstractions. Use [plugins]({{ '/docs/plugins/' | relative_url }}) when you need to share custom resources across projects.

### Where can I find community plugins?

```bash
gem search itamae-plugin
```

Or browse [RubyGems.org](https://rubygems.org/search?query=itamae-plugin).

---

## 🔧 Troubleshooting

### How do I debug a failing recipe?

1. **Increase log level** to see every command Itamae runs:

   ```bash
   itamae local --log-level debug recipe.rb
   ```

2. **Use dry-run** to preview changes without applying:

   ```bash
   itamae local --dry-run recipe.rb
   ```

3. **Use `run_command`** in a `local_ruby_block` to inspect state:

   ```ruby
   local_ruby_block 'debug' do
     block do
       result = run_command('cat /etc/os-release')
       Itamae.logger.info result.stdout
     end
   end
   ```

### Why does my recipe run successfully but nothing changes?

Common causes:
- The resource **action is `:nothing`** -- the default for `service` and some notification-only patterns
- A **guard** (`not_if` / `only_if`) is causing the resource to be skipped
- The system is **already in the desired state** -- Itamae is idempotent, so no change is correct behavior

Run with `--log-level debug` to see exactly which resources are skipped and why.

### What do the exit codes mean?

| Code | Meaning |
|------|---------|
| `0` | Success (no changes, or changes applied without `--detailed_exitcode`) |
| `1` | Execution failed |
| `2` | Success with changes (only with `--detailed_exitcode`) |

### How do I profile slow recipes?

```bash
itamae local --profile /tmp/profile.json recipe.rb
```

This writes a JSON file with per-command execution times:

```json
[
  {"command": "apt-get install -y nginx", "duration": 3.21},
  {"command": "systemctl enable nginx", "duration": 0.42}
]
```
