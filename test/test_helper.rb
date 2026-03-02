require 'bundler/setup'
require 'minitest/autorun'
require 'itamae'

# Mock backend that does nothing - resources only call backend during #run,
# not during #initialize, so this is sufficient for instantiation tests.
class MockBackend
  def run_command(*args)
    OpenStruct.new(stdout: '', stderr: '', exit_status: 0)
  end

  def host_inventory
    {}
  end
end

# Mock runner providing the interface resources access via recipe.runner
class MockRunner
  attr_reader :backend, :node, :tmpdir, :children, :handler, :options

  def initialize
    @backend  = MockBackend.new
    @options  = { dry_run: true }
    @node     = Itamae::Node.new({}, @backend)
    @tmpdir   = '/tmp/itamae_tmp'
    @children = Itamae::RecipeChildren.new
    @handler  = Itamae::HandlerProxy.new
  end

  def dry_run?
    true
  end

  def diff_found!; end
end

# Mock recipe providing the interface Resource::Base#initialize needs
class MockRecipe
  attr_reader :runner, :path, :children, :delayed_notifications

  def initialize(runner = MockRunner.new)
    @runner = runner
    @path = '/mock/recipe.rb'
    @children = Itamae::RecipeChildren.new
    @delayed_notifications = []
  end

  def dir
    ::File.dirname(@path)
  end
end

module ItamaeTestHelpers
  # Build any Itamae resource with a DSL block, using mock objects.
  # Returns the instantiated resource.
  #
  #   resource = build_resource(Itamae::Resource::Package, 'nginx') do
  #     version '1.18'
  #   end
  def build_resource(klass, name, &block)
    recipe = MockRecipe.new
    klass.new(recipe, name, &block)
  end

  # Assert a resource attribute has the expected value.
  def assert_attribute(resource, attr, expected)
    actual = resource.attributes[attr]
    assert_equal expected, actual,
      "Expected #{attr} to be #{expected.inspect}, got #{actual.inspect}"
  end

  # Assert a notification description matches the 'type[name]' format.
  def assert_valid_notification_format(desc)
    assert_match(/\A\w+\[.+\]\z/, desc,
      "Notification '#{desc}' does not match 'type[name]' format")
  end

  # Assert that creating a resource with an invalid type raises an error.
  def assert_invalid_type(klass, name, &block)
    assert_raises(Itamae::Resource::InvalidTypeError) do
      build_resource(klass, name, &block)
    end
  end

  # Assert that creating a resource with a missing required attribute raises.
  def assert_missing_attribute(klass, name, &block)
    assert_raises(Itamae::Resource::AttributeMissingError) do
      build_resource(klass, name, &block)
    end
  end
end
