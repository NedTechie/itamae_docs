require_relative '../test_helper'

class UserManagementExampleTest < Minitest::Test
  include ItamaeTestHelpers

  def test_group_admins
    r = build_resource(Itamae::Resource::Group, 'admins') do
      gid 2000
    end
    assert_attribute r, :groupname, 'admins'
    assert_attribute r, :gid, 2000
    assert_instance_of Integer, r.attributes[:gid]
  end

  def test_user_alice
    r = build_resource(Itamae::Resource::User, 'alice') do
      uid 2001
      gid 2000
      home '/home/alice'
      shell '/bin/bash'
      create_home true
    end
    assert_attribute r, :username, 'alice'
    assert_attribute r, :uid, 2001
    assert_attribute r, :home, '/home/alice'
    assert_attribute r, :shell, '/bin/bash'
    assert_attribute r, :create_home, true
  end

  def test_directory_ssh
    r = build_resource(Itamae::Resource::Directory, '/home/alice/.ssh') do
      owner 'alice'
      group 'alice'
      mode '0700'
    end
    assert_attribute r, :path, '/home/alice/.ssh'
    assert_attribute r, :mode, '0700'
  end

  def test_file_authorized_keys
    r = build_resource(Itamae::Resource::File, '/home/alice/.ssh/authorized_keys') do
      content 'ssh-ed25519 AAAA... alice@example.com'
      owner 'alice'
      group 'alice'
      mode '0600'
    end
    assert_attribute r, :path, '/home/alice/.ssh/authorized_keys'
    assert_attribute r, :mode, '0600'
    assert_instance_of String, r.attributes[:content]
  end

  def test_template_sudoers
    r = build_resource(Itamae::Resource::Template, '/etc/sudoers.d/admins') do
      source 'templates/sudoers.erb'
      owner 'root'
      group 'root'
      mode '0440'
      variables(admin_group: 'admins')
    end
    assert_attribute r, :mode, '0440'
    assert_equal 'admins', r.attributes[:variables][:admin_group]
  end

  def test_execute_validate_sudoers_with_guard
    r = build_resource(Itamae::Resource::Execute, 'validate-sudoers') do
      only_if 'test -f /etc/sudoers.d/admins'
    end
    refute_nil r.instance_variable_get(:@only_if_command)
  end

  def test_user_default_create_home
    r = build_resource(Itamae::Resource::User, 'testuser')
    assert_attribute r, :create_home, false
  end

  def test_group_invalid_gid_type
    assert_invalid_type(Itamae::Resource::Group, 'badgroup') do
      gid 'not-an-integer'
    end
  end
end
