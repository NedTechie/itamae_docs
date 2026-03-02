---
title: Handlers
---

Handlers receive events during recipe execution for logging, monitoring, and integration with external systems.

## Configuration

Configure handlers in a YAML config file:

```yaml
# itamae.yml
handlers:
  - type: json
    path: /var/log/itamae/events.jsonl
  - type: debug
```

```bash
itamae local -c itamae.yml recipe.rb
```

## Built-in Handlers

### Debug Handler

Logs all events to stdout. Useful for development and troubleshooting.

```yaml
handlers:
  - type: debug
```

### JSON Handler

Writes events as JSON lines to a file. Useful for log aggregation and analysis.

```yaml
handlers:
  - type: json
    path: /var/log/itamae/events.jsonl
```

### Fluentd Handler

Sends events to a Fluentd collector. Useful for centralized monitoring.

```yaml
handlers:
  - type: fluentd
    host: localhost
    port: 24224
    tag_prefix: itamae_server
```

> Requires the `fluent-logger` gem to be installed.

## Event Types

Handlers receive events throughout the recipe lifecycle:

| Event | Description |
|-------|-------------|
| `recipe_started` | Recipe execution begins |
| `recipe_completed` | Recipe execution finishes successfully |
| `recipe_failed` | Recipe execution fails |
| `resource_started` | Resource processing begins |
| `resource_completed` | Resource processing finishes |
| `resource_failed` | Resource processing fails |
| `resource_updated` | Resource made changes |
| `action_started` | Individual action begins |
| `action_completed` | Individual action finishes |
| `action_failed` | Individual action fails |
| `attribute_changed` | Resource attribute was modified |
| `file_content_changed` | File content diff detected |

## Custom Handlers

Create a custom handler by inheriting from `Itamae::Handler::Base`:

```ruby
class Itamae::Handler::MyHandler < Itamae::Handler::Base
  def initialize(options = {})
    @webhook_url = options[:webhook_url]
  end

  def event(type, payload = {})
    case type
    when :recipe_completed
      # Send notification
    when :resource_failed
      # Alert on failure
    end
  end
end
```

Configure in YAML:

```yaml
handlers:
  - type: my_handler
    webhook_url: https://hooks.example.com/itamae
```
