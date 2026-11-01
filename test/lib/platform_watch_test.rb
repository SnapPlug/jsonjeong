require "test_helper"

class PlatformWatchTest < ActiveSupport::TestCase
  test "릴리스 규칙: 보안·마이너만 통과" do
    assert_equal "security", PlatformWatch.release_status({ "tag_name" => "v8.1.3.1", "body" => "" })
    assert_equal "security", PlatformWatch.release_status({ "tag_name" => "v16.1.3", "body" => "Fixes CVE-2026-1234" })
    assert_equal "minor", PlatformWatch.release_status({ "tag_name" => "v16.5.0", "body" => "" })
    assert_nil PlatformWatch.release_status({ "tag_name" => "v8.1.4", "body" => "bug fixes" })
    assert_nil PlatformWatch.release_status({ "tag_name" => "v16.5.0-canary.36", "prerelease" => true })
  end

  test "Rails 보안 릴리스는 우리 줄기만, 새 마이너는 어느 줄기든" do
    ours = PlatformWatch::OUR_RAILS
    assert_equal "security", PlatformWatch.release_status({ "tag_name" => "v#{ours}.3.1" }, source: "rails")
    assert_nil PlatformWatch.release_status({ "tag_name" => "v7.2.3.2" }, source: "rails")
    assert_nil PlatformWatch.release_status({ "tag_name" => "v8.0.5.1", "body" => "security" }, source: "rails")
    assert_equal "minor", PlatformWatch.release_status({ "tag_name" => "v8.2.0" }, source: "rails")
  end
end
