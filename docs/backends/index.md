---
title: "🖥️ Backends"
---

Itamae uses backends to abstract command execution and file transfer across different target environments. All backends use [Specinfra](https://github.com/mizzy/specinfra) under the hood.

## 💻 Local Backend

Execute commands directly on the local machine. No additional configuration needed.

```bash
itamae local recipe.rb
```

Best for:
- Configuring the machine running Itamae
- Development and testing
- CI/CD pipelines

## 🔐 SSH Backend

Execute commands on remote machines via SSH.

```bash
itamae ssh --host web01.example.com recipe.rb
```

### ⚙️ Options

| Option | Description |
|--------|-------------|
| `--host` | Target hostname or IP |
| `--user` | SSH username |
| `--key` | Path to SSH private key |
| `--port` | SSH port |
| `--ssh_config` | Path to SSH config file |
| `--vagrant` | Auto-configure from Vagrant |
| `--ask_password` | Prompt for password |
| `--sudo` | Enable sudo (default: true) |

### 📦 Vagrant Integration

Connect to Vagrant VMs automatically:

```bash
itamae ssh --vagrant --host default recipe.rb
```

Itamae reads the Vagrant SSH config for the named VM.

### 📄 SSH Config File

Use a custom SSH config:

```bash
itamae ssh --ssh_config ~/.ssh/custom_config --host myserver recipe.rb
```

## 🐳 Docker Backend

Apply recipes to build Docker images. Itamae creates a container from a base image, applies recipes, then commits the result.

```bash
itamae docker --image ubuntu:22.04 --tag myapp:latest recipe.rb
```

### Options

| Option | Description |
|--------|-------------|
| `--image` | Base Docker image |
| `--container` | Base container ID (instead of image) |
| `--tag` | Tag for the resulting image |
| `--tls_verify_peer` | SSL verification (default: true) |

### 🔄 From an existing container

```bash
itamae docker --container abc123 --tag myapp:configured recipe.rb
```

## 🔒 Jail Backend (FreeBSD)

Execute commands inside a FreeBSD jail:

```bash
itamae jail --jail_name myjail recipe.rb
```

| Option | Description |
|--------|-------------|
| `--jail_name` | Jail hostname |

## 🔧 Backend Methods

All backends provide these operations to recipes and resources:

| Method | Description |
|--------|-------------|
| `run_command(cmd, opts)` | Execute a shell command on the target |
| `get_command(type, *args)` | Build a command via Specinfra |
| `receive_file(src, dst)` | Download a file from the target |
| `send_file(src, dst)` | Upload a file to the target |
| `send_directory(src, dst)` | Upload a directory to the target |
| `host_inventory` | Get system inventory facts |

## 📊 Host Inventory

Access system facts via `node`:

```ruby
# Available after backend initializes
node[:platform]           # e.g., "ubuntu"
node[:platform_version]   # e.g., "22.04"
node[:memory][:total]     # total memory
```

Host inventory data is lazy-loaded from system commands on the target.
