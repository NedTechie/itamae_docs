---
title: run_command
---

The `run_command` method executes shell commands on the target host and returns the result. It can be used in recipes, definitions, resource blocks, and `local_ruby_block` contexts.

## Return Value

`run_command` returns a `Specinfra::CommandResult` with:

| Attribute | Description |
|-----------|-------------|
| `stdout` | Standard output |
| `stderr` | Standard error |
| `exit_status` | Exit code (0 = success) |

## Usage

### In a recipe

```ruby
result = run_command('echo -n Hello')
result.stdout       # => "Hello"
result.exit_status  # => 0
```

### In a definition

```ruby
define :my_setup do
  result = run_command('cat /etc/os-release')
  if result.stdout.include?('Ubuntu')
    package 'ubuntu-keyring'
  end
end
```

### In a resource block

```ruby
execute 'conditional command' do
  result = run_command('cat /etc/hostname')
  command "echo 'Running on #{result.stdout.strip}'"
end
```

### In a local_ruby_block

```ruby
local_ruby_block 'check kernel' do
  block do
    result = run_command('uname -r')
    Itamae.logger.info "Kernel: #{result.stdout.strip}"
  end
end
```

## Error Handling

By default, `run_command` raises an error if the command exits with a non-zero status. The error includes stdout and stderr for debugging.

## Comparison with `execute` Resource

| Feature | `run_command` | `execute` resource |
|---------|---------------|-------------------|
| Returns output | Yes | No |
| Idempotency guards | No | `only_if` / `not_if` |
| Notifications | No | Yes |
| Logged as resource | No | Yes |
| Use case | Inline logic | Declarative commands |

Use `run_command` for querying state and making decisions. Use the `execute` resource for commands that change state.
