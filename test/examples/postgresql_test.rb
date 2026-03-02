require_relative '../test_helper'

class PostgresqlExampleTest < Minitest::Test
  include ItamaeTestHelpers

  def test_package_postgresql
    r = build_resource(Itamae::Resource::Package, 'postgresql-15')
    assert_attribute r, :name, 'postgresql-15'
    assert_attribute r, :action, :install
  end

  def test_group_postgres
    r = build_resource(Itamae::Resource::Group, 'postgres') do
      gid 118
    end
    assert_attribute r, :groupname, 'postgres'
    assert_attribute r, :gid, 118
    assert_instance_of Integer, r.attributes[:gid]
  end

  def test_user_postgres
    r = build_resource(Itamae::Resource::User, 'postgres') do
      uid 118
      gid 118
      home '/var/lib/postgresql'
      shell '/bin/bash'
      system_user true
    end
    assert_attribute r, :username, 'postgres'
    assert_attribute r, :uid, 118
    assert_attribute r, :shell, '/bin/bash'
    assert_attribute r, :system_user, true
    assert_instance_of Integer, r.attributes[:uid]
  end

  def test_directory_data_dir
    r = build_resource(Itamae::Resource::Directory, '/var/lib/postgresql/15/main') do
      owner 'postgres'
      group 'postgres'
      mode '0700'
    end
    assert_attribute r, :mode, '0700'
    assert_attribute r, :owner, 'postgres'
  end

  def test_template_postgresql_conf_notification
    r = build_resource(Itamae::Resource::Template, '/etc/postgresql/15/main/postgresql.conf') do
      source 'templates/postgresql.conf.erb'
      owner 'postgres'
      mode '0644'
      variables(
        max_connections: 200,
        shared_buffers: '256MB',
        effective_cache_size: '1GB',
        data_dir: '/var/lib/postgresql/15/main'
      )
      notifies :restart, 'service[postgresql]'
    end
    vars = r.attributes[:variables]
    assert_equal 200, vars[:max_connections]
    assert_equal '256MB', vars[:shared_buffers]

    assert_equal 1, r.notifications.length
    assert_equal :restart, r.notifications.first.action
    assert_valid_notification_format r.notifications.first.target_resource_desc
  end

  def test_template_pg_hba_reload
    r = build_resource(Itamae::Resource::Template, '/etc/postgresql/15/main/pg_hba.conf') do
      source 'templates/pg_hba.conf.erb'
      owner 'postgres'
      mode '0640'
      variables(db_name: 'myapp_production', db_user: 'myapp')
      notifies :reload, 'service[postgresql]'
    end
    assert_equal :reload, r.notifications.first.action
    assert_equal 'service[postgresql]', r.notifications.first.target_resource_desc
  end

  def test_execute_create_user_with_guard
    r = build_resource(Itamae::Resource::Execute, 'create-user-myapp') do
      not_if "sudo -u postgres psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname='myapp'\" | grep -q 1"
    end
    assert_attribute r, :action, :run
    refute_nil r.instance_variable_get(:@not_if_command)
  end

  def test_service_postgresql
    r = build_resource(Itamae::Resource::Service, 'postgresql') do
      action [:enable, :start]
    end
    assert_attribute r, :name, 'postgresql'
    assert_attribute r, :action, [:enable, :start]
  end

  def test_user_invalid_uid_type
    assert_invalid_type(Itamae::Resource::User, 'baduser') do
      uid 'not-an-integer'
    end
  end
end
