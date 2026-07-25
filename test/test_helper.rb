ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    def sign_in_as(user, password: "password")
      post session_path, params: { email: user.email, password: password }
    end

    # Minitest 6 removed Object#stub; temporary class-method override for isolation.
    def stub_singleton(target, method_name, value_or_callable)
      singleton = target.singleton_class
      original = singleton.instance_method(method_name)
      singleton.define_method(method_name) do |*args, **kwargs, &block|
        if value_or_callable.respond_to?(:call)
          value_or_callable.call(*args, **kwargs, &block)
        else
          value_or_callable
        end
      end
      yield
    ensure
      singleton.define_method(method_name, original)
    end
  end
end
