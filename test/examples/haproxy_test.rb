require_relative '../test_helper'

class HaproxyExampleTest < Minitest::Test
  include ItamaeTestHelpers

  def test_package_haproxy
    r = build_resource(Itamae::Resource::Package, 'haproxy')
    assert_attribute r, :name, 'haproxy'
    assert_attribute r, :action, :install
  end

  def test_directory_etc_haproxy
    r = build_resource(Itamae::Resource::Directory, '/etc/haproxy') do
      owner 'root'
      group 'root'
      mode '0755'
    end
    assert_attribute r, :path, '/etc/haproxy'
    assert_attribute r, :mode, '0755'
  end

  def test_directory_var_lib
    r = build_resource(Itamae::Resource::Directory, '/var/lib/haproxy') do
      owner 'haproxy'
      group 'haproxy'
      mode '0750'
    end
    assert_attribute r, :owner, 'haproxy'
    assert_attribute r, :mode, '0750'
  end

  def test_file_sysctl
    r = build_resource(Itamae::Resource::File, '/etc/sysctl.d/99-haproxy.conf') do
      content "net.core.somaxconn = 4096\nnet.ipv4.ip_nonlocal_bind = 1\n"
      owner 'root'
      mode '0644'
    end
    assert_kind_of String, r.attributes[:content]
    assert_includes r.attributes[:content], 'somaxconn'
  end

  def test_template_haproxy_cfg_notification
    r = build_resource(Itamae::Resource::Template, '/etc/haproxy/haproxy.cfg') do
      source 'templates/haproxy.cfg.erb'
      owner 'root'
      mode '0644'
      variables(
        stats_port: 8404,
        stats_user: 'admin',
        stats_password: 'haproxy-stats-pass',
        frontend_port: 443,
        frontend_http_port: 80,
        ssl_cert_path: '/etc/ssl/private/app.pem',
        backend_port: 3000,
        backend_servers: [
          { 'name' => 'app01', 'address' => '10.0.1.10' },
          { 'name' => 'app02', 'address' => '10.0.1.11' }
        ],
        health_check_path: '/health',
        health_check_interval: 5000,
        max_connections: 4096,
        timeout_connect: 5000,
        timeout_client: 50000,
        timeout_server: 50000
      )
      notifies :reload, 'service[haproxy]'
    end
    vars = r.attributes[:variables]
    assert_equal 8404, vars[:stats_port]
    assert_equal 443, vars[:frontend_port]
    assert_kind_of Array, vars[:backend_servers]
    assert_equal 2, vars[:backend_servers].length
    assert_equal '/health', vars[:health_check_path]

    assert_equal 1, r.notifications.length
    assert_equal :reload, r.notifications.first.action
    assert_valid_notification_format r.notifications.first.target_resource_desc
  end

  def test_execute_sysctl_with_guard
    r = build_resource(Itamae::Resource::Execute, 'sysctl-haproxy-somaxconn') do
      not_if 'sysctl net.core.somaxconn | grep -q 4096'
    end
    refute_nil r.instance_variable_get(:@not_if_command)
  end

  def test_execute_check_config_with_guard
    r = build_resource(Itamae::Resource::Execute, 'haproxy-check-config') do
      only_if 'test -f /etc/haproxy/haproxy.cfg'
    end
    refute_nil r.instance_variable_get(:@only_if_command)
  end

  def test_service_haproxy
    r = build_resource(Itamae::Resource::Service, 'haproxy') do
      action [:enable, :start]
    end
    assert_attribute r, :name, 'haproxy'
    assert_attribute r, :action, [:enable, :start]
  end

  def test_package_invalid_version_type
    assert_invalid_type(Itamae::Resource::Package, 'haproxy') do
      version 2.8
    end
  end
end
