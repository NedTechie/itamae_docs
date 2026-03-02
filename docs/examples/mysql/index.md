---
title: "Example: MySQL Database"
---

# MySQL Database

Install and configure MySQL with application databases, user privileges, automated backups, and performance tuning.

## Directory Structure

```
cookbooks/
  mysql/
    default.rb
    templates/
      mysqld.cnf.erb
      mysql-backup.sh.erb
      my.cnf.erb
nodes/
  db01.json
```

## Node Attributes

```json
{
  "mysql": {
    "version": "8.0",
    "port": 3306,
    "bind_address": "0.0.0.0",
    "data_dir": "/var/lib/mysql",
    "innodb_buffer_pool_size": "1G",
    "max_connections": 200,
    "query_cache_size": "64M",
    "slow_query_log": true,
    "slow_query_time": 2,
    "db_name": "myapp_production",
    "db_user": "myapp",
    "db_password": "s3cure-db-pass",
    "db_host": "10.0.%",
    "root_password": "r00t-s3cret",
    "backup_dir": "/var/backups/mysql",
    "backup_retention_days": 7
  }
}
```

## Recipe

```ruby
# cookbooks/mysql/default.rb

mysql = node['mysql']

package 'mysql-server' do
  action :install
end

group 'mysql' do
  gid 3306
end

user 'mysql' do
  uid 3306
  gid 3306
  home mysql['data_dir']
  shell '/usr/sbin/nologin'
  system_user true
end

directory mysql['data_dir'] do
  owner 'mysql'
  group 'mysql'
  mode '0750'
end

directory mysql['backup_dir'] do
  owner 'mysql'
  group 'mysql'
  mode '0750'
end

directory '/var/log/mysql' do
  owner 'mysql'
  group 'mysql'
  mode '0750'
end

template '/etc/mysql/mysql.conf.d/mysqld.cnf' do
  source 'templates/mysqld.cnf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    port: mysql['port'],
    bind_address: mysql['bind_address'],
    data_dir: mysql['data_dir'],
    innodb_buffer_pool_size: mysql['innodb_buffer_pool_size'],
    max_connections: mysql['max_connections'],
    slow_query_log: mysql['slow_query_log'],
    slow_query_time: mysql['slow_query_time']
  )
  notifies :restart, 'service[mysql]'
end

# Create application database and user
execute "create-db-#{mysql['db_name']}" do
  command "mysql -u root -e \"CREATE DATABASE IF NOT EXISTS #{mysql['db_name']} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;\""
  not_if "mysql -u root -e \"SHOW DATABASES LIKE '#{mysql['db_name']}'\" | grep -q #{mysql['db_name']}"
end

execute "create-user-#{mysql['db_user']}" do
  command "mysql -u root -e \"CREATE USER IF NOT EXISTS '#{mysql['db_user']}'@'#{mysql['db_host']}' IDENTIFIED BY '#{mysql['db_password']}'; GRANT ALL PRIVILEGES ON #{mysql['db_name']}.* TO '#{mysql['db_user']}'@'#{mysql['db_host']}'; FLUSH PRIVILEGES;\""
  not_if "mysql -u root -e \"SELECT User FROM mysql.user WHERE User='#{mysql['db_user']}'\" | grep -q #{mysql['db_user']}"
end

# Client config for root (passwordless local access)
template '/root/.my.cnf' do
  source 'templates/my.cnf.erb'
  owner 'root'
  group 'root'
  mode '0600'
  variables(
    root_password: mysql['root_password']
  )
end

# Backup script
template '/usr/local/bin/mysql-backup.sh' do
  source 'templates/mysql-backup.sh.erb'
  owner 'root'
  group 'root'
  mode '0755'
  variables(
    db_name: mysql['db_name'],
    backup_dir: mysql['backup_dir'],
    retention_days: mysql['backup_retention_days']
  )
end

service 'mysql' do
  action [:enable, :start]
end
```

## Templates

### mysqld.cnf.erb

```erb
[mysqld]
port = <%= @port %>
bind-address = <%= @bind_address %>
datadir = <%= @data_dir %>

innodb_buffer_pool_size = <%= @innodb_buffer_pool_size %>
max_connections = <%= @max_connections %>

<% if @slow_query_log %>
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = <%= @slow_query_time %>
<% end %>

log_error = /var/log/mysql/error.log

character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
```

### my.cnf.erb

```erb
[client]
user = root
password = <%= @root_password %>
```

### mysql-backup.sh.erb

```erb
#!/bin/bash
BACKUP_DIR="<%= @backup_dir %>"
DB_NAME="<%= @db_name %>"
RETENTION=<%= @retention_days %>

mysqldump --single-transaction "$DB_NAME" | gzip > "$BACKUP_DIR/${DB_NAME}_$(date +%Y%m%d_%H%M%S).sql.gz"
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +"$RETENTION" -delete
```

## Running

```bash
itamae ssh -j nodes/db01.json -h db01.example.com cookbooks/mysql/default.rb
```
