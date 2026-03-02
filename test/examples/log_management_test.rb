require_relative '../test_helper'

class LogManagementExampleTest < Minitest::Test
  include ItamaeTestHelpers

  def test_package_rsyslog
    r = build_resource(Itamae::Resource::Package, 'rsyslog')
    assert_attribute r, :name, 'rsyslog'
    assert_attribute r, :action, :install
  end

  def test_template_rsyslog_forward_notification
    r = build_resource(Itamae::Resource::Template, '/etc/rsyslog.d/50-remote.conf') do
      source 'templates/rsyslog-forward.conf.erb'
      owner 'root'
      group 'root'
      mode '0644'
      variables(
        remote_host: 'logs.example.com',
        remote_port: 514,
        protocol: 'tcp',
        app_name: 'myapp'
      )
      notifies :restart, 'service[rsyslog]'
    end
    vars = r.attributes[:variables]
    assert_equal 'logs.example.com', vars[:remote_host]
    assert_equal 514, vars[:remote_port]
    assert_equal 'tcp', vars[:protocol]

    assert_equal 1, r.notifications.length
    assert_equal :restart, r.notifications.first.action
    assert_valid_notification_format r.notifications.first.target_resource_desc
  end

  def test_directory_app_log
    r = build_resource(Itamae::Resource::Directory, '/var/log/myapp') do
      owner 'deploy'
      group 'deploy'
      mode '0755'
    end
    assert_attribute r, :path, '/var/log/myapp'
    assert_attribute r, :owner, 'deploy'
  end

  def test_template_logrotate
    r = build_resource(Itamae::Resource::Template, '/etc/logrotate.d/myapp') do
      source 'templates/logrotate-app.erb'
      owner 'root'
      mode '0644'
      variables(
        app_log_dir: '/var/log/myapp',
        rotate_count: 14,
        rotate_size: '100M',
        app_user: 'deploy'
      )
    end
    assert_equal 14, r.attributes[:variables][:rotate_count]
    assert_equal '100M', r.attributes[:variables][:rotate_size]
  end

  def test_template_journald_notification
    r = build_resource(Itamae::Resource::Template, '/etc/systemd/journald.conf.d/size.conf') do
      source 'templates/journald.conf.erb'
      owner 'root'
      mode '0644'
      variables(
        max_size: '500M',
        max_age: '30d'
      )
      notifies :restart, 'service[systemd-journald]'
    end
    assert_equal '500M', r.attributes[:variables][:max_size]
    assert_equal :restart, r.notifications.first.action
    assert_valid_notification_format r.notifications.first.target_resource_desc
  end

  def test_service_rsyslog
    r = build_resource(Itamae::Resource::Service, 'rsyslog') do
      action [:enable, :start]
    end
    assert_attribute r, :name, 'rsyslog'
    assert_attribute r, :action, [:enable, :start]
  end

  def test_service_journald
    r = build_resource(Itamae::Resource::Service, 'systemd-journald') do
      action [:enable, :start]
    end
    assert_attribute r, :name, 'systemd-journald'
  end

  def test_template_invalid_variables_type
    assert_invalid_type(Itamae::Resource::Template, '/etc/bad.conf') do
      source 'templates/bad.erb'
      variables 'not-a-hash'
    end
  end
end
