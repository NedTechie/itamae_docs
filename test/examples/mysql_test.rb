require_relative '../test_helper'

class MysqlExampleTest < Minitest::Test
  include ItamaeTestHelpers

  def test_package_mysql
    r = build_resource(Itamae::Resource::Package, 'mysql-server')
    assert_attribute r, :name, 'mysql-server'
    assert_attribute r, :action, :install
  end

  def test_group_mysql
    r = build_resource(Itamae::Resource::Group, 'mysql') do
      gid 3306
    end
    assert_attribute r, :groupname, 'mysql'
    assert_attribute r, :gid, 3306
  end

  def test_user_mysql
    r = build_resource(Itamae::Resource::User, 'mysql') do
      uid 3306
      gid 3306
      home '/var/lib/mysql'
      shell '/usr/sbin/nologin'
      system_user true
    end
    assert_attribute r, :username, 'mysql'
    assert_attribute r, :uid, 3306
    assert_attribute r, :system_user, true
  end

  def test_directory_data
    r = build_resource(Itamae::Resource::Directory, '/var/lib/mysql') do
      owner 'mysql'
      group 'mysql'
      mode '0750'
    end
    assert_attribute r, :mode, '0750'
    assert_attribute r, :owner, 'mysql'
  end

  def test_template_mysqld_cnf_notification
    r = build_resource(Itamae::Resource::Template, '/etc/mysql/mysql.conf.d/mysqld.cnf') do
      source 'templates/mysqld.cnf.erb'
      owner 'root'
      mode '0644'
      variables(
        port: 3306,
        bind_address: '0.0.0.0',
        data_dir: '/var/lib/mysql',
        innodb_buffer_pool_size: '1G',
        max_connections: 200,
        slow_query_log: true,
        slow_query_time: 2
      )
      notifies :restart, 'service[mysql]'
    end
    vars = r.attributes[:variables]
    assert_equal 3306, vars[:port]
    assert_equal '1G', vars[:innodb_buffer_pool_size]
    assert_equal 200, vars[:max_connections]
    assert_equal true, vars[:slow_query_log]

    assert_equal 1, r.notifications.length
    assert_equal :restart, r.notifications.first.action
    assert_valid_notification_format r.notifications.first.target_resource_desc
  end

  def test_template_root_mycnf
    r = build_resource(Itamae::Resource::Template, '/root/.my.cnf') do
      source 'templates/my.cnf.erb'
      owner 'root'
      group 'root'
      mode '0600'
      variables(root_password: 'r00t-s3cret')
    end
    assert_attribute r, :mode, '0600'
    assert_equal 'r00t-s3cret', r.attributes[:variables][:root_password]
  end

  def test_execute_create_db_with_guard
    r = build_resource(Itamae::Resource::Execute, 'create-db-myapp_production') do
      not_if "mysql -u root -e \"SHOW DATABASES LIKE 'myapp_production'\" | grep -q myapp_production"
    end
    assert_attribute r, :action, :run
    refute_nil r.instance_variable_get(:@not_if_command)
  end

  def test_service_mysql
    r = build_resource(Itamae::Resource::Service, 'mysql') do
      action [:enable, :start]
    end
    assert_attribute r, :name, 'mysql'
    assert_attribute r, :action, [:enable, :start]
  end

  def test_user_invalid_uid_type
    assert_invalid_type(Itamae::Resource::User, 'baduser') do
      uid 'not-an-integer'
    end
  end
end
