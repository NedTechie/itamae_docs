---
title: "📋 Node Attributes"
---

Node attributes provide host-specific data to your recipes. They allow you to write generic recipes that adapt to different environments.

## 📥 Loading Attributes

### 📄 From JSON

```bash
itamae local --node-json node.json recipe.rb
```

```json
{
  "hostname": "web01",
  "app": {
    "port": 3000,
    "workers": 4
  }
}
```

### 📝 From YAML

```bash
itamae local --node-yaml node.yml recipe.rb
```

```yaml
hostname: web01
app:
  port: 3000
  workers: 4
```

### 📚 Multiple files

Load and deep-merge multiple attribute files. Later files take precedence:

```bash
itamae local -j base.json -j web.json -y overrides.yml recipe.rb
```

## 🔑 Accessing Attributes

Use the `node` object in recipes:

```ruby
execute "hostname #{node[:hostname]}"

template '/etc/app.conf' do
  variables(
    port: node[:app][:port],
    workers: node[:app][:workers]
  )
end
```

In templates, access `node` directly:

```erb
hostname = <%= node[:hostname] %>
port = <%= node[:app][:port] %>
```

### 🔀 Flexible access

Node attributes use `Hashie::Mash`, so you can access them with symbols, strings, or method syntax:

```ruby
node[:app][:port]      # symbol keys
node['app']['port']    # string keys
node.app.port          # method syntax
```

## ✅ Validation

Validate attributes before recipe execution to catch configuration errors early:

```ruby
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
```

Validation types:
- `string` -- must be a String
- `integer` -- must be an Integer
- `boolean` -- must be true or false
- `optional(type)` -- may be nil
- `array_of(type)` -- array where each element matches type

When validation fails, provisioning halts with an error message.

## 📊 Host Inventory

Itamae automatically collects system facts from the target host. These are merged into node attributes:

```ruby
node[:platform]           # "ubuntu", "centos", etc.
node[:platform_version]   # "22.04", "9", etc.
```

Host inventory data is lazy-loaded when first accessed.

## ⚠️ Ohai Integration (Deprecated)

Load comprehensive system data via Ohai:

```bash
itamae local --ohai recipe.rb
```

> If Ohai is not found on the target host, Itamae will install it. This option is deprecated -- prefer host inventory or explicit node JSON/YAML.
