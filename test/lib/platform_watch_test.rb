require "test_helper"

class PlatformWatchTest < ActiveSupport::TestCase
  test "릴리스 규칙: 보안·마이너만 통과" do
    assert_equal "security", PlatformWatch.release_status({ "tag_name" => "v8.1.3.1", "body" => "" })
    assert_equal "security", PlatformWatch.release_status({ "tag_name" => "v16.1.3", "body" => "Fixes CVE-2026-1234" })
    assert_equal "minor", PlatformWatch.release_status({ "tag_name" => "v16.5.0", "body" => "" })
    assert_nil PlatformWatch.release_status({ "tag_name" => "v8.1.4", "body" => "bug fixes" })
    assert_nil PlatformWatch.release_status({ "tag_name" => "v16.5.0-canary.36", "prerelease" => true })
  end

  test "보안 판정은 공지 번호나 보안 수정 문구로만: 단어 security만으로는 아니다" do
    next_patch = ->(body) { PlatformWatch.release_status({ "tag_name" => "v16.4.4", "body" => body }, source: "nextjs") }
    # 16.4.4 실제 문구: 버그 수정 릴리스가 다음 보안 릴리스를 예고했다
    assert_nil next_patch.call("The [announced security released for November](https://nextjs.org/blog/upcoming-nextjs-security-release-november-2026) will be published tomorrow.")
    # Rails 8.1.2 실제 문구: 기능 이름에 security가 들어 있다
    assert_nil next_patch.call("Fix `content_security_policy_nonce` error in mailers")
    assert_equal "security", next_patch.call("This release contains security fixes for the following advisories:")
    assert_equal "security", next_patch.call("advisories/GHSA-673q-mjm6-r5xr")
    assert_equal "security", next_patch.call("This release contains additional security hardening for `next/og`.")
  end

  test "Rails 보안 릴리스는 우리 줄기만, 새 마이너는 어느 줄기든" do
    ours = PlatformWatch::OUR_RAILS
    assert_equal "security", PlatformWatch.release_status({ "tag_name" => "v#{ours}.3.1" }, source: "rails")
    assert_nil PlatformWatch.release_status({ "tag_name" => "v7.2.3.2" }, source: "rails")
    assert_nil PlatformWatch.release_status({ "tag_name" => "v8.0.5.1", "body" => "security" }, source: "rails")
    assert_equal "minor", PlatformWatch.release_status({ "tag_name" => "v8.2.0" }, source: "rails")
  end
end
