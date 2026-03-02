---
title: "🔍 Dry-Run Mode"
---

# 🔍 Dry-Run Mode

Dry-run mode lets you **preview exactly what Itamae would change** on your system without actually applying any modifications. It's your safety net before every production run.

## 🚀 Quick Start

```bash
# Long flag
itamae local --dry-run recipe.rb

# Short flag (-n)
itamae ssh -n -h web01.example.com recipe.rb

# Works with all backends
itamae docker -n --image ubuntu:22.04 recipe.rb
```

The startup banner confirms you're in dry-run mode:

```
 INFO : Starting Itamae... (dry-run)
```

## ⚙️ How It Works

Dry-run executes the **full resource lifecycle** — except the actual system mutation. Here's exactly what happens at each step:

| Step | Normal Mode | 🔍 Dry-Run Mode |
|------|:-----------:|:---------------:|
| 1️⃣ Initialize resource | ✅ Runs | ✅ Runs |
| 2️⃣ Evaluate guards (`only_if`/`not_if`) | ✅ Runs | ✅ Runs |
| 3️⃣ `pre_action` (gather state) | ✅ Runs | ✅ Runs |
| 4️⃣ `set_current_attributes` (query target) | ✅ Runs | ✅ Runs |
| 5️⃣ `show_differences` (display diffs) | ✅ Runs | ✅ Runs |
| 6️⃣ **`action_*` method (apply changes)** | ✅ **Runs** | ❌ **Skipped** |
| 7️⃣ `verify` commands | ✅ Runs | ❌ **Skipped** |
| 8️⃣ Detect differences | ✅ Runs | ✅ Runs |
| 9️⃣ Fire notifications | ✅ Runs | ✅ Runs* |

> 💡 **Key insight:** Notifications *do* fire in dry-run mode (so you see the full chain), but the notified resource's action is also skipped by the same dry-run guard.

## 📋 What You See in Dry-Run Output

Dry-run output is **identical** to a normal run — you see every attribute change and file diff — but no actual changes are applied.

### Attribute Changes

```
 INFO : Recipe: /path/to/recipe.rb
 INFO :   package[nginx]
 INFO :     installed will change from 'false' to 'true'
 INFO :   service[nginx]
 INFO :     enabled will change from 'false' to 'true'
 INFO :     running will change from 'false' to 'true'
```

### File Content Diffs

For `file`, `template`, and `remote_file` resources, Itamae shows a unified diff of what would change:

```diff
 INFO :   template[/etc/nginx/nginx.conf]
 INFO :     diff:
 --- /etc/nginx/nginx.conf
 +++ /tmp/itamae_tmp/...
 @@ -1,3 +1,3 @@
 -worker_processes 2;
 +worker_processes 4;
  events {
 -    worker_connections 512;
 +    worker_connections 1024;
```

> 🔒 Files marked with `sensitive true` suppress the diff output to protect secrets.

### Notification Chain

```
 INFO :   template[/etc/nginx/nginx.conf]
 INFO :     Notifying restart to service resource 'nginx' (delayed)
```

## 🔬 Per-Resource Behavior

Different resources behave differently during dry-run because `pre_action` and `set_current_attributes` **still run** (they query the target to gather comparison data).

### 📦 package

State is fully queried — you see exactly which packages would be installed or removed and their version changes.

### ⚡ execute

The execute resource **always marks itself as changed** (every run is considered an update). In dry-run, the command itself is skipped, but you will see:

```
 INFO :   execute[apt-get update]
 INFO :     executed will change from 'false' to 'true'
```

> ⚠️ **Important:** Guards (`only_if`/`not_if`) on execute resources **still run** their commands in dry-run mode. This is necessary to determine whether the resource would execute.

### 📄 file / template / remote_file

These resources upload a temp file to the target and run `diff` even in dry-run mode, so you get **full content diffs**. The actual file is never moved into place.

For `template` resources, the ERB rendering happens locally before the diff comparison, so you see the rendered output.

### 📂 directory

Mode, owner, and group are queried from the existing directory. You see what permissions would change.

### 🔗 link

The current symlink target is read. You see whether the link would be created or updated.

### 👤 user / 👥 group

Current uid, gid, home, shell are queried. You see exactly which attributes would be updated.

### 🔄 service

Running and enabled states are queried. You see which services would start, stop, enable, or disable.

### 🌐 http_request

> ⚠️ **Note:** The HTTP request is **actually made** during `pre_action` (to fetch the response body for diff comparison). The downloaded content is compared but not written to the target path. Be aware of this side effect when dry-running recipes with `http_request`.

### 📁 remote_directory

The source directory is uploaded to a temp path on the target for comparison. A recursive `diff -u -r` shows what would change. The actual directory is not moved into place.

### 🐙 git

The repository state is not deeply checked during dry-run. The destination directory existence is verified.

### 💎 gem_package

The `gem list -l` command runs to check installed gems. You see which gems would be installed, upgraded, or removed.

### 💻 local_ruby_block

> ⚠️ **Important:** The Ruby block is **not executed** in dry-run mode (it's inside the `action_run` method, which is skipped). There's no way to preview what a `local_ruby_block` would do.

## 🔄 Combining with `--detailed_exitcode`

Use both flags together for CI/CD pipelines to detect whether changes *would* be made:

```bash
itamae local --dry-run --detailed_exitcode recipe.rb
echo $?
# 0 = no changes needed
# 2 = changes would be applied
# 1 = error occurred
```

### CI/CD Pattern

```bash
#!/bin/bash
set -e

# Preview first
itamae ssh --dry-run --detailed_exitcode \
  -h "$HOST" -j "nodes/${HOST}.json" roles/web.rb

case $? in
  0) echo "✅ No changes needed" ;;
  2) echo "⚠️  Changes detected — review above and run without --dry-run" ;;
  *) echo "❌ Error during dry-run" ; exit 1 ;;
esac
```

## 💡 Best Practices

### ✅ Always Dry-Run Before Production

```bash
# Step 1: Preview
itamae ssh --dry-run -h production.example.com -j nodes/prod.json recipe.rb

# Step 2: Review the output carefully

# Step 3: Apply
itamae ssh -h production.example.com -j nodes/prod.json recipe.rb
```

### ✅ Use with Log Levels

Combine `--dry-run` with `--log_level debug` for maximum visibility:

```bash
itamae local --dry-run --log_level debug recipe.rb
```

Debug mode shows:
- Every specinfra command being run
- SHA256 comparisons for file content
- Template rendering details
- Guard command output

### ✅ Test Node Attribute Changes

When modifying node JSON files, dry-run shows the impact:

```bash
# See what changing worker_processes from 2 to 4 would do
itamae ssh --dry-run -h web01 -j nodes/web01-updated.json cookbooks/nginx/default.rb
```

### ⚠️ Limitations to Be Aware Of

1. **Guards execute real commands** — `only_if` and `not_if` commands run on the target even in dry-run mode
2. **`http_request` makes real HTTP calls** — the URL is fetched during `pre_action`
3. **`execute` resources can't show what would happen** — they always report "will change"
4. **`local_ruby_block` is opaque** — the block is not called, so you can't preview its effects
5. **State queries touch the target** — `pre_action` and `set_current_attributes` run real commands to gather current state (this is necessary for accurate diffs)
6. **Dependent resources may see stale state** — since earlier resources don't actually apply changes, later resources in the same run may see pre-change state and report inaccurate diffs
