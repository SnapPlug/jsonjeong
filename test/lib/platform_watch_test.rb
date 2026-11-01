require "test_helper"

class PlatformWatchTest < ActiveSupport::TestCase
  test "릴리스 규칙: 보안·마이너만 통과" do
    assert_equal "security", PlatformWatch.release_status("tag_name" => "v8.1.3.1", "body" => "")
    assert_equal "security", PlatformWatch.release_status("tag_name" => "v16.1.3", "body" => "Fixes CVE-2026-1234")
    assert_equal "minor", PlatformWatch.release_status("tag_name" => "v16.5.0", "body" => "")
    assert_nil PlatformWatch.release_status("tag_name" => "v8.1.4", "body" => "bug fixes")
    assert_nil PlatformWatch.release_status("tag_name" => "v16.5.0-canary.36", "prerelease" => true)
  end
end
