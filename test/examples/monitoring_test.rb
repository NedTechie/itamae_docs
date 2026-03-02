require_relative '../test_helper'

class MonitoringExampleTest < Minitest::Test
  include ItamaeTestHelpers

  def test_user_node_exporter
    r = build_resource(Itamae::Resource::User, 'node_exporter') do
      uid 9100
      gid 9100
      home '/var/lib/node_exporter'
      shell '/usr/sbin/nologin'
      system_user true
    end
    assert_attribute r, :username, 'node_exporter'
    assert_attribute r, :uid, 9100
    assert_attribute r, :system_user, true
  end

  def test_directory_textfile
    r = build_resource(Itamae::Resource::Directory, '/var/lib/node_exporter/textfile') do
      owner 'node_exporter'
      group 'node_exporter'
      mode '0755'
    end
    assert_attribute r, :path, '/var/lib/node_exporter/textfile'
    assert_attribute r, :mode, '0755'
  end

  def test_execute_download_with_guard
    r = build_resource(Itamae::Resource::Execute, 'download-node-exporter') do
      not_if 'test -f /usr/local/bin/node_exporter'
    end
    assert_attribute r, :action, :run
    refute_nil r.instance_variable_get(:@not_if_command)
  end

  def test_file_node_exporter_binary
    r = build_resource(Itamae::Resource::File, '/usr/local/bin/node_exporter') do
      owner 'root'
      group 'root'
      mode '0755'
    end
    assert_attribute r, :path, '/usr/local/bin/node_exporter'
    assert_attribute r, :mode, '0755'
  end

  def test_template_systemd_service_notification
    r = build_resource(Itamae::Resource::Template, '/etc/systemd/system/node_exporter.service') do
      source 'templates/node_exporter.service.erb'
      owner 'root'
      mode '0644'
      variables(
        user: 'node_exporter',
        port: 9100,
        textfile_dir: '/var/lib/node_exporter/textfile'
      )
      notifies :restart, 'service[node_exporter]'
    end
    assert_equal 9100, r.attributes[:variables][:port]
    assert_equal 1, r.notifications.length
    assert_equal :restart, r.notifications.first.action
    assert_valid_notification_format r.notifications.first.target_resource_desc
  end

  def test_http_request_health_check
    r = build_resource(Itamae::Resource::HttpRequest, '/tmp/health_check') do
      url 'https://health.example.com/ping'
    end
    assert_attribute r, :url, 'https://health.example.com/ping'
    assert_attribute r, :action, :get
    assert_attribute r, :headers, {}
  end

  def test_service_node_exporter
    r = build_resource(Itamae::Resource::Service, 'node_exporter') do
      action [:enable, :start]
    end
    assert_attribute r, :name, 'node_exporter'
    assert_attribute r, :action, [:enable, :start]
  end

  def test_http_request_missing_url
    assert_missing_attribute(Itamae::Resource::HttpRequest, '/tmp/bad')
  end
end
