ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # Minitest 6에는 stub이 없다(minitest-mock 젬으로 분리됨). 모듈의 싱글턴 메서드 하나를 블록 동안만 바꾼다.
    # value가 호출 가능하면 인자를 넘겨 호출하고, 아니면 그 값을 그대로 돌려준다.
    def stubbing(object, name, value)
      original = object.singleton_class.instance_method(name)
      object.define_singleton_method(name) { |*args, &block| value.respond_to?(:call) ? value.call(*args, &block) : value }
      yield
    ensure
      object.define_singleton_method(name, original)
    end
  end
end
