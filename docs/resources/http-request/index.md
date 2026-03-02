---
title: http_request
---

Make HTTP requests as part of your recipes. The response body is saved to a file.

## Actions

| Action | Description |
|--------|-------------|
| `:get` | HTTP GET request (default) |
| `:post` | HTTP POST request |
| `:put` | HTTP PUT request |
| `:delete` | HTTP DELETE request |
| `:options` | HTTP OPTIONS request |
| `:nothing` | Do nothing (use with notifications) |

## Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `url` | String | **required** | URL to request |
| `path` | String | Resource name | Destination file for the response body |
| `headers` | Hash | `{}` | HTTP headers |
| `message` | String | `""` | Request body (for POST/PUT) |
| `redirect_limit` | Integer | `10` | Maximum number of redirects to follow |
| `mode` | String | -- | File permissions for saved response |
| `owner` | String | -- | File owner |
| `group` | String | -- | File group |

## Examples

### Download a file

```ruby
http_request '/tmp/archive.tar.gz' do
  url 'https://example.com/releases/v1.0.tar.gz'
end
```

### POST with headers

```ruby
http_request '/tmp/api_response.json' do
  action :post
  url 'https://api.example.com/deploy'
  headers('Authorization' => 'Bearer token123',
          'Content-Type' => 'application/json')
  message '{"environment": "production"}'
end
```

### Download with permissions

```ruby
http_request '/usr/local/bin/tool' do
  url 'https://releases.example.com/tool-linux-amd64'
  mode '0755'
  owner 'root'
end
```
