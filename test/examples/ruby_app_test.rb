require_relative '../test_helper'

class RubyAppExampleTest < Minitest::Test
  include ItamaeTestHelpers

  def test_user_deploy
    r = build_resource(Itamae::Resource::User, 'deploy') do
      uid 1001
      gid 1001
      home '/home/deploy'
      shell '/bin/bash'
      create_home true
    end
    assert_attribute r, :username, 'deploy'
    assert_attribute r, :uid, 1001
    assert_attribute r, :create_home, true
  end

  def test_directory_shared_config
    r = build_resource(Itamae::Resource::Directory, '/var/www/myapp/shared/config') do
      owner 'deploy'
      group 'deploy'
      mode '0755'
    end
    assert_attribute r, :path, '/var/www/myapp/shared/config'
    assert_attribute r, :mode, '0755'
  end

  def test_gem_package_bundler
    r = build_resource(Itamae::Resource::GemPackage, 'bundler') do
      version '2.4.0'
    end
    assert_attribute r, :package_name, 'bundler'
    assert_attribute r, :version, '2.4.0'
    assert_attribute r, :action, :install
  end

  def test_git_clone_app
    r = build_resource(Itamae::Resource::Git, '/var/www/myapp/releases/current') do
      repository 'https://github.com/example/myapp.git'
      revision 'main'
    end
    assert_attribute r, :destination, '/var/www/myapp/releases/current'
    assert_attribute r, :repository, 'https://github.com/example/myapp.git'
    assert_attribute r, :revision, 'main'
    assert_attribute r, :action, :sync
  end

  def test_template_puma_config_notification
    r = build_resource(Itamae::Resource::Template, '/var/www/myapp/shared/config/puma.rb') do
      source 'templates/puma.rb.erb'
      owner 'deploy'
      mode '0644'
      variables(
        deploy_to: '/var/www/myapp',
        workers: 2,
        threads_min: 1,
        threads_max: 5,
        port: 3000
      )
      notifies :restart, 'service[puma]'
    end
    assert_equal 2, r.attributes[:variables][:workers]
    assert_equal 1, r.notifications.length
    assert_equal :restart, r.notifications.first.action
    assert_valid_notification_format r.notifications.first.target_resource_desc
  end

  def test_template_env_sensitive
    r = build_resource(Itamae::Resource::Template, '/var/www/myapp/shared/.env') do
      source 'templates/env.erb'
      owner 'deploy'
      mode '0600'
      variables(
        environment: 'production',
        secret_key_base: 'abc123',
        port: 3000
      )
      notifies :restart, 'service[puma]'
    end
    assert_attribute r, :mode, '0600'
    assert_equal 'production', r.attributes[:variables][:environment]
  end

  def test_link_current_release
    r = build_resource(Itamae::Resource::Link, '/var/www/myapp/current') do
      to '/var/www/myapp/releases/current'
    end
    assert_attribute r, :to, '/var/www/myapp/releases/current'
    assert_attribute r, :action, :create
  end

  def test_git_missing_repository
    assert_missing_attribute(Itamae::Resource::Git, '/var/www/app') do
      revision 'main'
    end
  end
end
