require_relative '../test_helper'

class SecurityExampleTest < Minitest::Test
  include ItamaeTestHelpers

  def test_template_sshd_config_notification
    r = build_resource(Itamae::Resource::Template, '/etc/ssh/sshd_config') do
      source 'templates/sshd_config.erb'
      owner 'root'
      mode '0600'
      variables(
        port: 2222,
        permit_root_login: 'no',
        password_authentication: 'no',
        allowed_users: %w[alice bob deploy]
      )
      notifies :restart, 'service[sshd]'
    end
    assert_attribute r, :mode, '0600'
    vars = r.attributes[:variables]
    assert_equal 2222, vars[:port]
    assert_kind_of Array, vars[:allowed_users]

    assert_equal 1, r.notifications.length
    assert_equal :restart, r.notifications.first.action
    assert_valid_notification_format r.notifications.first.target_resource_desc
  end

  def test_package_ufw
    r = build_resource(Itamae::Resource::Package, 'ufw')
    assert_attribute r, :name, 'ufw'
    assert_attribute r, :action, :install
  end

  def test_execute_ufw_allow_with_guard
    r = build_resource(Itamae::Resource::Execute, 'ufw-allow-2222') do
      not_if "ufw status | grep -q '2222/tcp'"
    end
    assert_attribute r, :action, :run
    refute_nil r.instance_variable_get(:@not_if_command)
  end

  def test_template_fail2ban_notification
    r = build_resource(Itamae::Resource::Template, '/etc/fail2ban/jail.local') do
      source 'templates/jail.local.erb'
      owner 'root'
      mode '0644'
      variables(
        ssh_port: 2222,
        maxretry: 3,
        bantime: 3600,
        findtime: 600
      )
      notifies :restart, 'service[fail2ban]'
    end
    vars = r.attributes[:variables]
    assert_equal 3, vars[:maxretry]
    assert_equal 3600, vars[:bantime]

    assert_equal :restart, r.notifications.first.action
    assert_valid_notification_format r.notifications.first.target_resource_desc
  end

  def test_directory_audit_rules
    r = build_resource(Itamae::Resource::Directory, '/etc/audit/rules.d') do
      owner 'root'
      group 'root'
      mode '0750'
    end
    assert_attribute r, :mode, '0750'
  end

  def test_template_audit_rules_notification
    r = build_resource(Itamae::Resource::Template, '/etc/audit/rules.d/itamae.rules') do
      source 'templates/audit.rules.erb'
      owner 'root'
      mode '0640'
      notifies :restart, 'service[auditd]'
    end
    assert_equal 'service[auditd]', r.notifications.first.target_resource_desc
    assert_valid_notification_format r.notifications.first.target_resource_desc
  end

  def test_service_sshd
    r = build_resource(Itamae::Resource::Service, 'sshd') do
      action [:enable, :start]
    end
    assert_attribute r, :name, 'sshd'
    assert_attribute r, :action, [:enable, :start]
  end

  def test_template_invalid_mode_type
    assert_invalid_type(Itamae::Resource::Template, '/etc/bad') do
      source 'templates/bad.erb'
      mode 755
    end
  end
end
