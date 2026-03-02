require_relative '../test_helper'

class LetsencryptExampleTest < Minitest::Test
  include ItamaeTestHelpers

  def test_package_certbot
    r = build_resource(Itamae::Resource::Package, 'certbot')
    assert_attribute r, :name, 'certbot'
    assert_attribute r, :action, :install
  end

  def test_package_certbot_nginx_plugin
    r = build_resource(Itamae::Resource::Package, 'python3-certbot-nginx')
    assert_attribute r, :name, 'python3-certbot-nginx'
    assert_attribute r, :action, :install
  end

  def test_directory_webroot
    r = build_resource(Itamae::Resource::Directory, '/var/www/certbot') do
      owner 'www-data'
      group 'www-data'
      mode '0755'
    end
    assert_attribute r, :path, '/var/www/certbot'
    assert_attribute r, :owner, 'www-data'
  end

  def test_template_ssl_params_notification
    r = build_resource(Itamae::Resource::Template, '/etc/nginx/snippets/ssl-params.conf') do
      source 'templates/ssl-params.conf.erb'
      owner 'root'
      group 'root'
      mode '0644'
      variables(ssl_dir: '/etc/letsencrypt')
      notifies :reload, 'service[nginx]'
    end
    assert_equal '/etc/letsencrypt', r.attributes[:variables][:ssl_dir]
    assert_equal 1, r.notifications.length
    assert_equal :reload, r.notifications.first.action
    assert_valid_notification_format r.notifications.first.target_resource_desc
  end

  def test_execute_certbot_initial_with_guard
    r = build_resource(Itamae::Resource::Execute, 'certbot-initial-example.com') do
      not_if 'test -d /etc/letsencrypt/live/example.com'
    end
    assert_attribute r, :action, :run
    refute_nil r.instance_variable_get(:@not_if_command)
  end

  def test_template_cron_renewal
    r = build_resource(Itamae::Resource::Template, '/etc/cron.d/certbot-renew') do
      source 'templates/certbot-renew.cron.erb'
      owner 'root'
      group 'root'
      mode '0644'
      variables(renew_hook: 'systemctl reload nginx')
    end
    assert_attribute r, :mode, '0644'
    assert_equal 'systemctl reload nginx', r.attributes[:variables][:renew_hook]
  end

  def test_execute_dhparam_with_guard
    r = build_resource(Itamae::Resource::Execute, 'generate-dhparam') do
      not_if 'test -f /etc/letsencrypt/dhparam.pem'
    end
    refute_nil r.instance_variable_get(:@not_if_command)
  end

  def test_service_nginx
    r = build_resource(Itamae::Resource::Service, 'nginx') do
      action [:enable, :start]
    end
    assert_attribute r, :name, 'nginx'
    assert_attribute r, :action, [:enable, :start]
  end

  def test_directory_invalid_mode_type
    assert_invalid_type(Itamae::Resource::Directory, '/bad') do
      mode 755
    end
  end
end
