---
title: "Example: Jenkins CI Server"
---

# Jenkins CI Server

Provision a Jenkins CI/CD server with Java runtime, plugin management, and build agent configuration.

## Directory Structure

```
cookbooks/
  jenkins/
    default.rb
    templates/
      jenkins-defaults.erb
      jenkins-nginx.conf.erb
nodes/
  ci01.json
```

## Node Attributes

```json
{
  "jenkins": {
    "http_port": 8080,
    "home_dir": "/var/lib/jenkins",
    "java_version": "17",
    "memory_max": "2g",
    "memory_min": "512m",
    "admin_user": "admin",
    "agent_port": 50000,
    "proxy_server_name": "ci.example.com",
    "executors": 4,
    "plugins": ["git", "pipeline", "docker-workflow", "blueocean"]
  }
}
```

## Recipe

```ruby
# cookbooks/jenkins/default.rb

jen = node['jenkins']

# --- Java Runtime ---

package "openjdk-#{jen['java_version']}-jdk-headless" do
  action :install
end

# --- Jenkins Repository ---

execute 'add-jenkins-key' do
  command 'curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null'
  not_if 'test -f /usr/share/keyrings/jenkins-keyring.asc'
end

execute 'add-jenkins-repo' do
  command 'echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list'
  not_if 'test -f /etc/apt/sources.list.d/jenkins.list'
end

execute 'apt-update-jenkins' do
  command 'apt-get update'
end

package 'jenkins' do
  action :install
end

# --- Jenkins directories ---

directory jen['home_dir'] do
  owner 'jenkins'
  group 'jenkins'
  mode '0755'
end

directory "#{jen['home_dir']}/plugins" do
  owner 'jenkins'
  group 'jenkins'
  mode '0755'
end

directory '/var/log/jenkins' do
  owner 'jenkins'
  group 'jenkins'
  mode '0750'
end

# --- JVM and Jenkins defaults ---

template '/etc/default/jenkins' do
  source 'templates/jenkins-defaults.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    http_port: jen['http_port'],
    home_dir: jen['home_dir'],
    memory_max: jen['memory_max'],
    memory_min: jen['memory_min'],
    agent_port: jen['agent_port']
  )
  notifies :restart, 'service[jenkins]'
end

# --- Install plugins via CLI ---

jen['plugins'].each do |plugin|
  execute "install-plugin-#{plugin}" do
    command "java -jar #{jen['home_dir']}/war/WEB-INF/jenkins-cli.jar -s http://localhost:#{jen['http_port']}/ install-plugin #{plugin}"
    not_if "test -d #{jen['home_dir']}/plugins/#{plugin}"
  end
end

# --- Nginx reverse proxy ---

package 'nginx' do
  action :install
end

template '/etc/nginx/sites-available/jenkins' do
  source 'templates/jenkins-nginx.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    server_name: jen['proxy_server_name'],
    http_port: jen['http_port']
  )
  notifies :reload, 'service[nginx]'
end

link '/etc/nginx/sites-enabled/jenkins' do
  to '/etc/nginx/sites-available/jenkins'
  notifies :reload, 'service[nginx]'
end

service 'jenkins' do
  action [:enable, :start]
end

service 'nginx' do
  action [:enable, :start]
end
```

## Templates

### jenkins-defaults.erb

```erb
JENKINS_HOME="<%= @home_dir %>"
JENKINS_PORT="<%= @http_port %>"
JENKINS_ARGS="--httpPort=<%= @http_port %>"
JAVA_ARGS="-Xms<%= @memory_min %> -Xmx<%= @memory_max %> -Djava.awt.headless=true -Dhudson.model.DirectoryBrowserSupport.CSP= -Djenkins.model.Jenkins.slaveAgentPort=<%= @agent_port %>"
```

### jenkins-nginx.conf.erb

```erb
upstream jenkins {
    server 127.0.0.1:<%= @http_port %>;
    keepalive 32;
}

server {
    listen 80;
    server_name <%= @server_name %>;

    location / {
        proxy_pass http://jenkins;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 90;
    }
}
```

## Running

```bash
itamae ssh -j nodes/ci01.json -h ci01.example.com cookbooks/jenkins/default.rb
```
