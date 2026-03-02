---
title: "🌐 http_request"
---

# 🌐 http_request

Make HTTP requests and save the response body to a file. Inherits from [`file`]({{ '/docs/resources/file/' | relative_url }}).

## ⚡ Actions

| Action | Description |
|--------|-------------|
| `:get` | HTTP GET request **(default)** |
| `:post` | HTTP POST request |
| `:put` | HTTP PUT request |
| `:delete` | HTTP DELETE request |
| `:options` | HTTP OPTIONS request |
| `:nothing` | Do nothing (use with notifications) |

## 📋 Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `url` | String | **required** ⚠️ | URL to request |
| `path` | String | Resource name | Destination file for the response body |
| `headers` | Hash | `{}` | HTTP request headers |
| `message` | String | `""` | Request body (for POST/PUT) |
| `redirect_limit` | Integer | `10` | Maximum number of redirects to follow |
| `mode` | String | — | File permissions for saved response |
| `owner` | String | — | File owner |
| `group` | String | — | File group |
| `sensitive` | Boolean | `false` | Hide content diff in output 🔒 |

## 🔍 How It Works

1. 🌐 **Fetch** — Makes the HTTP request, following redirects up to `redirect_limit`
2. 📥 **Save** — Sets response body as the file content
3. 📊 **Compare** — Diffs response content against the existing file
4. 📄 **Write** — Saves to the destination path (using the `file` resource's write logic)

### Error Handling

| HTTP Status | Behavior |
|-------------|----------|
| 2xx ✅ | Success — saves response body |
| 3xx ↩️ | Follows redirect (up to `redirect_limit`) |
| 4xx ❌ | Raises `HTTPClientError` |
| 5xx 💥 | Raises `HTTPServerError` |

> 💡 HTTPS is supported — SSL is automatically enabled for `https://` URLs.

## 🔬 Dry-Run Behavior

> ⚠️ **Important:** The HTTP request is **actually made** during `pre_action` (to fetch the response body for diff comparison). The content is compared but not written to the target path. Be aware of this side effect.

## 📖 Examples

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
  headers(
    'Authorization' => 'Bearer token123',
    'Content-Type' => 'application/json'
  )
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

### Download with redirect following

```ruby
http_request '/tmp/latest-release.tar.gz' do
  url 'https://github.com/user/repo/releases/latest/download/app.tar.gz'
  redirect_limit 5
end
```

## 🧬 Inheritance

Inherits from `file` — all file attributes (`mode`, `owner`, `group`, `sensitive`) are available.

> ⚠️ **Note:** The standard `file` actions (`:create`, `:delete`, `:edit`) are **replaced** by HTTP verb actions. You cannot use `:create` or `:edit` on an `http_request` resource.
