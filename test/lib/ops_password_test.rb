require "test_helper"
require "rake"

class OpsPasswordTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("ops:password")
    ENV["OPS_EMAIL"] = "ops@example.com"
  end

  teardown do
    ENV.delete("OPS_PASSWORD")
    ENV.delete("OPS_EMAIL")
  end

  test "OPS_PASSWORD가 없으면 아무것도 하지 않는다" do
    ENV.delete("OPS_PASSWORD")
    assert_no_difference "User.count" do
      Rake::Task["ops:password"].execute
    end
  end

  test "OPS_PASSWORD가 있으면 계정을 만들고, 바뀌면 비밀번호를 맞춘다" do
    ENV["OPS_PASSWORD"] = "first-secret"
    assert_difference "User.count", 1 do
      Rake::Task["ops:password"].execute
    end
    assert User.find_by!(email_address: "ops@example.com").authenticate("first-secret")

    ENV["OPS_PASSWORD"] = "second-secret"
    assert_no_difference "User.count" do
      Rake::Task["ops:password"].execute
    end
    assert User.find_by!(email_address: "ops@example.com").authenticate("second-secret")
  end
end
