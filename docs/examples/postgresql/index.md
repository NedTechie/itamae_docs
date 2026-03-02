---
title: "Example: PostgreSQL Database"
---

# PostgreSQL Database

Set up PostgreSQL with dedicated users, database creation, connection tuning, and automated backups.

## Directory Structure

```
cookbooks/
  postgresql/
    default.rb
    templates/
      postgresql.conf.erb
      pg_hba.conf.erb
      backup.sh.erb
nodes/
  db01.json
```

## Node Attributes

```json
{
  "postgresql": {
    "version": "15",
    "data_dir": "/var/lib/postgresql/15/main",
    "max_connections": 200,
    "shared_buffers": "256MB",
    "effective_cache_size": "1GB",
    "db_name": "myapp_production",
    "db_user": "myapp",
    "db_password": "secret",
    "backup_dir": "/var/backups/postgresql",
    "backup_retention_days": 7
  }
}
```

## Recipe

```ruby
# cookbooks/postgresql/default.rb

version = node['postgresql']['version']

package "postgresql-#{version}" do
  action :install
end

group 'postgres' do
  gid 118
end

user 'postgres' do
  uid 118
  gid 118
  home '/var/lib/postgresql'
  shell '/bin/bash'
  system_user true
end

directory node['postgresql']['data_dir'] do
  owner 'postgres'
  group 'postgres'
  mode '0700'
end

directory node['postgresql']['backup_dir'] do
  owner 'postgres'
  group 'postgres'
  mode '0750'
end

template '/etc/postgresql/15/main/postgresql.conf' do
  source 'templates/postgresql.conf.erb'
  owner 'postgres'
  group 'postgres'
  mode '0644'
  variables(
    max_connections: node['postgresql']['max_connections'],
    shared_buffers: node['postgresql']['shared_buffers'],
    effective_cache_size: node['postgresql']['effective_cache_size'],
    data_dir: node['postgresql']['data_dir']
  )
  notifies :restart, 'service[postgresql]'
end

template '/etc/postgresql/15/main/pg_hba.conf' do
  source 'templates/pg_hba.conf.erb'
  owner 'postgres'
  group 'postgres'
  mode '0640'
  variables(
    db_name: node['postgresql']['db_name'],
    db_user: node['postgresql']['db_user']
  )
  notifies :reload, 'service[postgresql]'
end

execute "create-user-#{node['postgresql']['db_user']}" do
  command "sudo -u postgres createuser #{node['postgresql']['db_user']}"
  not_if "sudo -u postgres psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname='#{node['postgresql']['db_user']}'\" | grep -q 1"
end

execute "create-db-#{node['postgresql']['db_name']}" do
  command "sudo -u postgres createdb -O #{node['postgresql']['db_user']} #{node['postgresql']['db_name']}"
  not_if "sudo -u postgres psql -tAc \"SELECT 1 FROM pg_database WHERE datname='#{node['postgresql']['db_name']}'\" | grep -q 1"
end

template '/usr/local/bin/pg_backup.sh' do
  source 'templates/backup.sh.erb'
  owner 'root'
  group 'root'
  mode '0755'
  variables(
    db_name: node['postgresql']['db_name'],
    backup_dir: node['postgresql']['backup_dir'],
    retention_days: node['postgresql']['backup_retention_days']
  )
end

service 'postgresql' do
  action [:enable, :start]
end
```

## Templates

### postgresql.conf.erb

```erb
data_directory = '<%= @data_dir %>'
max_connections = <%= @max_connections %>
shared_buffers = '<%= @shared_buffers %>'
effective_cache_size = '<%= @effective_cache_size %>'
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d.log'
```

### pg_hba.conf.erb

```erb
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             postgres                                peer
local   all             all                                     peer
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             ::1/128                 scram-sha-256
host    <%= @db_name %> <%= @db_user %> 10.0.0.0/8             scram-sha-256
```

### backup.sh.erb

```erb
#!/bin/bash
BACKUP_DIR="<%= @backup_dir %>"
DB_NAME="<%= @db_name %>"
RETENTION=<%= @retention_days %>

pg_dump -U postgres "$DB_NAME" | gzip > "$BACKUP_DIR/${DB_NAME}_$(date +%Y%m%d).sql.gz"
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +"$RETENTION" -delete
```

## Running

```bash
itamae ssh -j nodes/db01.json -h db01.example.com cookbooks/postgresql/default.rb
```
