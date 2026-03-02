require_relative '../test_helper'

class MultiTierExampleTest < Minitest::Test
  include ItamaeTestHelpers

  # The multi-tier example composes individual cookbooks via include_recipe.
  # These tests verify that the component resources from each tier can be
  # instantiated correctly, validating the recipe patterns used in roles.

  def test_web_tier_nginx_package
    r = build_resource(Itamae::Resource::Package, 'nginx')
    assert_attribute r, :name, 'nginx'
    assert_attribute r, :action, :install
  end

  def test_app_tier_user
    r = build_resource(Itamae::Resource::User, 'deploy') do
      uid 1001
      gid 1001
      home '/home/deploy'
      shell '/bin/bash'
      create_home true
    end
    assert_attribute r, :username, 'deploy'
    assert_attribute r, :uid, 1001
  end

  def test_db_tier_postgresql_service
    r = build_resource(Itamae::Resource::Service, 'postgresql') do
      action [:enable, :start]
    end
    assert_attribute r, :name, 'postgresql'
    assert_attribute r, :action, [:enable, :start]
  end

  def test_base_role_security_template
    r = build_resource(Itamae::Resource::Template, '/etc/ssh/sshd_config') do
      source 'templates/sshd_config.erb'
      owner 'root'
      mode '0600'
      variables(
        port: 2222,
        permit_root_login: 'no',
        password_authentication: 'no',
        allowed_users: %w[alice deploy]
      )
      notifies :restart, 'service[sshd]'
    end
    assert_equal 2222, r.attributes[:variables][:port]
    assert_equal 1, r.notifications.length
    assert_valid_notification_format r.notifications.first.target_resource_desc
  end

  def test_base_role_monitoring_user
    r = build_resource(Itamae::Resource::User, 'node_exporter') do
      uid 9100
      gid 9100
      shell '/usr/sbin/nologin'
      system_user true
    end
    assert_attribute r, :system_user, true
    assert_attribute r, :uid, 9100
  end

  def test_cross_tier_link
    r = build_resource(Itamae::Resource::Link, '/etc/nginx/sites-enabled/app.conf') do
      to '/etc/nginx/sites-available/app.conf'
    end
    assert_attribute r, :to, '/etc/nginx/sites-available/app.conf'
    assert_attribute r, :action, :create
  end
end
