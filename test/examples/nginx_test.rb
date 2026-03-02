require_relative '../test_helper'

class NginxExampleTest < Minitest::Test
  include ItamaeTestHelpers

  def test_package_nginx
    r = build_resource(Itamae::Resource::Package, 'nginx')
    assert_attribute r, :name, 'nginx'
    assert_attribute r, :action, :install
  end

  def test_directory_sites_available
    r = build_resource(Itamae::Resource::Directory, '/etc/nginx/sites-available') do
      owner 'root'
      group 'root'
      mode '0755'
    end
    assert_attribute r, :path, '/etc/nginx/sites-available'
    assert_attribute r, :owner, 'root'
    assert_attribute r, :mode, '0755'
    assert_attribute r, :action, :create
  end

  def test_directory_log
    r = build_resource(Itamae::Resource::Directory, '/var/log/nginx') do
      owner 'www-data'
      group 'adm'
      mode '0750'
    end
    assert_attribute r, :owner, 'www-data'
    assert_attribute r, :group, 'adm'
  end

  def test_template_nginx_conf_with_notification
    r = build_resource(Itamae::Resource::Template, '/etc/nginx/nginx.conf') do
      source 'templates/nginx.conf.erb'
      owner 'root'
      mode '0644'
      variables(worker_processes: 4, worker_connections: 1024)
      notifies :reload, 'service[nginx]'
    end
    assert_attribute r, :path, '/etc/nginx/nginx.conf'
    assert_attribute r, :mode, '0644'
    assert_kind_of Hash, r.attributes[:variables]
    assert_equal 4, r.attributes[:variables][:worker_processes]

    assert_equal 1, r.notifications.length
    assert_equal :reload, r.notifications.first.action
    assert_equal 'service[nginx]', r.notifications.first.target_resource_desc
    assert_valid_notification_format r.notifications.first.target_resource_desc
  end

  def test_template_vhost_variables
    r = build_resource(Itamae::Resource::Template, '/etc/nginx/sites-available/app.conf') do
      source 'templates/vhost.conf.erb'
      owner 'root'
      mode '0644'
      variables(
        server_name: 'app.example.com',
        root: '/var/www/app/current/public',
        upstream_port: 3000,
        ssl_certificate: '/etc/ssl/certs/app.pem',
        ssl_certificate_key: '/etc/ssl/private/app.key'
      )
      notifies :reload, 'service[nginx]'
    end
    vars = r.attributes[:variables]
    assert_equal 'app.example.com', vars[:server_name]
    assert_equal 3000, vars[:upstream_port]
  end

  def test_link_site_enabled
    r = build_resource(Itamae::Resource::Link, '/etc/nginx/sites-enabled/app.conf') do
      to '/etc/nginx/sites-available/app.conf'
      notifies :reload, 'service[nginx]'
    end
    assert_attribute r, :to, '/etc/nginx/sites-available/app.conf'
    assert_equal 1, r.notifications.length
    assert_valid_notification_format r.notifications.first.target_resource_desc
  end

  def test_execute_remove_default_with_guard
    r = build_resource(Itamae::Resource::Execute, 'rm -f /etc/nginx/sites-enabled/default') do
      only_if 'test -f /etc/nginx/sites-enabled/default'
    end
    assert_attribute r, :action, :run
    refute_nil r.instance_variable_get(:@only_if_command)
  end

  def test_service_nginx
    r = build_resource(Itamae::Resource::Service, 'nginx') do
      action [:enable, :start]
    end
    assert_attribute r, :name, 'nginx'
    assert_attribute r, :action, [:enable, :start]
  end

  def test_package_invalid_version_type
    assert_invalid_type(Itamae::Resource::Package, 'nginx') do
      version 123
    end
  end
end
