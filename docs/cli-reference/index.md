---
title: CLI Reference
---

Itamae provides several commands for running recipes and scaffolding projects.

## Commands

### `itamae local`

Run recipes on the local machine.

```bash
itamae local [OPTIONS] RECIPE [RECIPE...]
```

### `itamae ssh`

Run recipes on a remote host via SSH.

```bash
itamae ssh [OPTIONS] RECIPE [RECIPE...]
```

**SSH-specific options:**

| Option | Description |
|--------|-------------|
| `-h, --host HOST` | Target hostname (required unless `--vagrant`) |
| `-u, --user USER` | SSH username |
| `-i, --key KEY` | SSH private key file |
| `-p, --port PORT` | SSH port |
| `--ssh_config PATH` | SSH config file |
| `--vagrant` | Connect to a Vagrant VM |
| `--ask_password` | Prompt for SSH password |
| `--sudo` | Enable sudo (default: true) |

### `itamae docker`

Build a Docker image by applying recipes to a base image or container.

```bash
itamae docker [OPTIONS] RECIPE [RECIPE...]
```

**Docker-specific options:**

| Option | Description |
|--------|-------------|
| `--image IMAGE` | Base Docker image (required if no `--container`) |
| `--container ID` | Base container (required if no `--image`) |
| `--tag TAG` | Tag for the created image |
| `--tls_verify_peer` | SSL peer verification (default: true) |

### `itamae jail`

Run recipes inside a FreeBSD jail.

```bash
itamae jail [OPTIONS] RECIPE [RECIPE...]
```

| Option | Description |
|--------|-------------|
| `--jail_name NAME` | Jail hostname |

### `itamae init`

Scaffold a new Itamae project.

```bash
itamae init NAME
```

Creates a project directory with `Gemfile`, `Rakefile`, and standard structure.

### `itamae generate` (alias: `g`)

Generate cookbooks or roles.

```bash
itamae generate cookbook NAME
itamae generate role NAME
```

### `itamae destroy` (alias: `d`)

Remove generated cookbooks or roles.

```bash
itamae destroy cookbook NAME
itamae destroy role NAME
```

### `itamae version`

Print the Itamae version.

## Global Options

Available for `local`, `ssh`, `docker`, and `jail` commands:

| Option | Description |
|--------|-------------|
| `-j, --node_json PATH` | Load node attributes from JSON (repeatable) |
| `-y, --node_yaml PATH` | Load node attributes from YAML (repeatable) |
| `-n, --dry_run` | Preview changes without applying |
| `-l, --log_level LEVEL` | `debug`, `info` (default), `warn`, `error`, `fatal` |
| `--color` | Enable/disable colored output (default: true) |
| `--shell PATH` | Shell to use (default: `/bin/sh`) |
| `--login_shell` | Use login shell |
| `-c, --config PATH` | Configuration file (YAML) |
| `-t, --tmp_dir PATH` | Temporary directory (default: `/tmp/itamae_tmp`) |
| `--detailed_exitcode` | Use detailed exit codes |
| `--recipe_graph PATH` | Write recipe dependency graph in DOT format (experimental) |
| `--profile PATH` | Save profiling data as JSON (experimental) |
| `--ohai` | Load system info via Ohai (deprecated) |

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success (no changes, or changes applied without `--detailed_exitcode`) |
| `1` | Execution failed |
| `2` | Success with changes (only with `--detailed_exitcode`) |

## Configuration File

You can store options in a YAML configuration file and pass it with `-c`:

```yaml
# itamae.yml
log_level: debug
color: true
tmp_dir: /tmp/itamae_custom
handlers:
  - type: json
    path: /var/log/itamae/events.jsonl
```

```bash
itamae local -c itamae.yml recipe.rb
```

## Multiple Node Attribute Files

Load and deep-merge multiple attribute files. Later files take precedence:

```bash
itamae local -j base.json -j web.json -y overrides.yml recipe.rb
```

## Profiling

Generate a JSON profile of command execution times:

```bash
itamae local --profile /tmp/profile.json recipe.rb
```

Output format:

```json
[
  {"command": "apt-get install -y nginx", "duration": 3.21},
  {"command": "systemctl enable nginx", "duration": 0.42}
]
```

## Dependency Graph

Generate a DOT graph of recipe dependencies:

```bash
itamae local --recipe_graph /tmp/deps.dot recipe.rb
dot -Tpng /tmp/deps.dot -o /tmp/deps.png
```
