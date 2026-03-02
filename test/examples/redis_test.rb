require_relative '../test_helper'

class RedisExampleTest < Minitest::Test
  include ItamaeTestHelpers

  def test_package_redis
    r = build_resource(Itamae::Resource::Package, 'redis-server')
    assert_attribute r, :name, 'redis-server'
    assert_attribute r, :action, :install
  end

  def test_group_redis
    r = build_resource(Itamae::Resource::Group, 'redis') do
      gid 6379
    end
    assert_attribute r, :groupname, 'redis'
    assert_attribute r, :gid, 6379
    assert_instance_of Integer, r.attributes[:gid]
  end

  def test_user_redis
    r = build_resource(Itamae::Resource::User, 'redis') do
      uid 6379
      gid 6379
      home '/var/lib/redis'
      shell '/usr/sbin/nologin'
      system_user true
    end
    assert_attribute r, :username, 'redis'
    assert_attribute r, :uid, 6379
    assert_attribute r, :system_user, true
  end

  def test_directory_data
    r = build_resource(Itamae::Resource::Directory, '/var/lib/redis') do
      owner 'redis'
      group 'redis'
      mode '0750'
    end
    assert_attribute r, :mode, '0750'
    assert_attribute r, :owner, 'redis'
  end

  def test_template_redis_conf_notification
    r = build_resource(Itamae::Resource::Template, '/etc/redis/redis.conf') do
      source 'templates/redis.conf.erb'
      owner 'redis'
      group 'redis'
      mode '0640'
      variables(
        port: 6379,
        bind_address: '127.0.0.1',
        maxmemory: '512mb',
        maxmemory_policy: 'allkeys-lru',
        save_intervals: ['900 1', '300 10', '60 10000'],
        requirepass: 's3cret-redis-pass',
        log_level: 'notice',
        data_dir: '/var/lib/redis',
        log_dir: '/var/log/redis'
      )
      notifies :restart, 'service[redis-server]'
    end
    assert_attribute r, :mode, '0640'
    vars = r.attributes[:variables]
    assert_equal 6379, vars[:port]
    assert_equal '512mb', vars[:maxmemory]
    assert_kind_of Array, vars[:save_intervals]
    assert_equal 3, vars[:save_intervals].length

    assert_equal 1, r.notifications.length
    assert_equal :restart, r.notifications.first.action
    assert_valid_notification_format r.notifications.first.target_resource_desc
  end

  def test_execute_disable_thp_with_guard
    r = build_resource(Itamae::Resource::Execute, 'disable-thp') do
      not_if 'grep -q "\\[never\\]" /sys/kernel/mm/transparent_hugepage/enabled'
    end
    assert_attribute r, :action, :run
    refute_nil r.instance_variable_get(:@not_if_command)
  end

  def test_execute_apply_sysctl_with_guard
    r = build_resource(Itamae::Resource::Execute, 'apply-sysctl-redis') do
      only_if 'test -f /etc/sysctl.d/99-redis.conf'
    end
    refute_nil r.instance_variable_get(:@only_if_command)
  end

  def test_service_redis
    r = build_resource(Itamae::Resource::Service, 'redis-server') do
      action [:enable, :start]
    end
    assert_attribute r, :name, 'redis-server'
    assert_attribute r, :action, [:enable, :start]
  end

  def test_template_invalid_mode_type
    assert_invalid_type(Itamae::Resource::Template, '/etc/redis/bad.conf') do
      source 'templates/bad.erb'
      mode 640
    end
  end
end
