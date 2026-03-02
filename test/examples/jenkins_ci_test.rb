require_relative '../test_helper'

class JenkinsCiExampleTest < Minitest::Test
  include ItamaeTestHelpers

  def test_package_java
    r = build_resource(Itamae::Resource::Package, 'openjdk-17-jdk-headless')
    assert_attribute r, :name, 'openjdk-17-jdk-headless'
    assert_attribute r, :action, :install
  end

  def test_package_jenkins
    r = build_resource(Itamae::Resource::Package, 'jenkins')
    assert_attribute r, :name, 'jenkins'
    assert_attribute r, :action, :install
  end

  def test_directory_jenkins_home
    r = build_resource(Itamae::Resource::Directory, '/var/lib/jenkins') do
      owner 'jenkins'
      group 'jenkins'
      mode '0755'
    end
    assert_attribute r, :path, '/var/lib/jenkins'
    assert_attribute r, :owner, 'jenkins'
  end

  def test_directory_plugins
    r = build_resource(Itamae::Resource::Directory, '/var/lib/jenkins/plugins') do
      owner 'jenkins'
      group 'jenkins'
      mode '0755'
    end
    assert_attribute r, :path, '/var/lib/jenkins/plugins'
    assert_attribute r, :mode, '0755'
  end

  def test_template_defaults_notification
    r = build_resource(Itamae::Resource::Template, '/etc/default/jenkins') do
      source 'templates/jenkins-defaults.erb'
      owner 'root'
      mode '0644'
      variables(
        http_port: 8080,
        home_dir: '/var/lib/jenkins',
        memory_max: '2g',
        memory_min: '512m',
        agent_port: 50000
      )
      notifies :restart, 'service[jenkins]'
    end
    vars = r.attributes[:variables]
    assert_equal 8080, vars[:http_port]
    assert_equal '2g', vars[:memory_max]
    assert_equal 50000, vars[:agent_port]

    assert_equal 1, r.notifications.length
    assert_equal :restart, r.notifications.first.action
    assert_valid_notification_format r.notifications.first.target_resource_desc
  end

  def test_template_nginx_proxy_notification
    r = build_resource(Itamae::Resource::Template, '/etc/nginx/sites-available/jenkins') do
      source 'templates/jenkins-nginx.conf.erb'
      owner 'root'
      mode '0644'
      variables(
        server_name: 'ci.example.com',
        http_port: 8080
      )
      notifies :reload, 'service[nginx]'
    end
    assert_equal 'ci.example.com', r.attributes[:variables][:server_name]
    assert_equal :reload, r.notifications.first.action
    assert_valid_notification_format r.notifications.first.target_resource_desc
  end

  def test_link_site_enabled
    r = build_resource(Itamae::Resource::Link, '/etc/nginx/sites-enabled/jenkins') do
      to '/etc/nginx/sites-available/jenkins'
      notifies :reload, 'service[nginx]'
    end
    assert_attribute r, :to, '/etc/nginx/sites-available/jenkins'
    assert_equal 1, r.notifications.length
    assert_valid_notification_format r.notifications.first.target_resource_desc
  end

  def test_execute_add_key_with_guard
    r = build_resource(Itamae::Resource::Execute, 'add-jenkins-key') do
      not_if 'test -f /usr/share/keyrings/jenkins-keyring.asc'
    end
    refute_nil r.instance_variable_get(:@not_if_command)
  end

  def test_service_jenkins
    r = build_resource(Itamae::Resource::Service, 'jenkins') do
      action [:enable, :start]
    end
    assert_attribute r, :name, 'jenkins'
    assert_attribute r, :action, [:enable, :start]
  end

  def test_link_missing_target
    assert_missing_attribute(Itamae::Resource::Link, '/etc/nginx/sites-enabled/bad')
  end
end
