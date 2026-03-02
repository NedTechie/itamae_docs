require_relative '../test_helper'

class DockerHostExampleTest < Minitest::Test
  include ItamaeTestHelpers

  def test_prerequisite_packages
    %w[apt-transport-https ca-certificates curl gnupg].each do |pkg|
      r = build_resource(Itamae::Resource::Package, pkg)
      assert_attribute r, :name, pkg
      assert_attribute r, :action, :install
    end
  end

  def test_execute_add_gpg_key_with_guard
    r = build_resource(Itamae::Resource::Execute, 'add-docker-gpg-key') do
      not_if 'test -f /usr/share/keyrings/docker-archive-keyring.gpg'
    end
    assert_attribute r, :action, :run
    refute_nil r.instance_variable_get(:@not_if_command)
  end

  def test_directory_etc_docker
    r = build_resource(Itamae::Resource::Directory, '/etc/docker') do
      owner 'root'
      group 'root'
      mode '0755'
    end
    assert_attribute r, :path, '/etc/docker'
    assert_attribute r, :mode, '0755'
  end

  def test_group_docker
    r = build_resource(Itamae::Resource::Group, 'docker')
    assert_attribute r, :groupname, 'docker'
    assert_attribute r, :action, :create
  end

  def test_template_daemon_json_notification
    r = build_resource(Itamae::Resource::Template, '/etc/docker/daemon.json') do
      source 'templates/daemon.json.erb'
      owner 'root'
      mode '0644'
      variables(
        storage_driver: 'overlay2',
        log_driver: 'json-file',
        log_max_size: '50m',
        log_max_file: 3,
        registry_mirrors: ['https://mirror.example.com']
      )
      notifies :restart, 'service[docker]'
    end
    vars = r.attributes[:variables]
    assert_equal 'overlay2', vars[:storage_driver]
    assert_kind_of Array, vars[:registry_mirrors]

    assert_equal 1, r.notifications.length
    assert_equal :restart, r.notifications.first.action
    assert_valid_notification_format r.notifications.first.target_resource_desc
  end

  def test_file_logrotate
    r = build_resource(Itamae::Resource::File, '/etc/logrotate.d/docker') do
      content "logrotate config content"
      owner 'root'
      mode '0644'
    end
    assert_attribute r, :path, '/etc/logrotate.d/docker'
    assert_instance_of String, r.attributes[:content]
  end

  def test_service_docker
    r = build_resource(Itamae::Resource::Service, 'docker') do
      action [:enable, :start]
    end
    assert_attribute r, :name, 'docker'
    assert_attribute r, :action, [:enable, :start]
  end

  def test_template_invalid_variables_type
    assert_invalid_type(Itamae::Resource::Template, '/etc/docker/bad.json') do
      source 'templates/bad.erb'
      variables 'not-a-hash'
    end
  end
end
