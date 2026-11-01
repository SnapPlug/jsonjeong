require "test_helper"

class SubmissionTest < ActiveSupport::TestCase
  def build(**over)
    Submission.new({ name: "테스트", email: "a@b.co", started_on: Date.new(2026, 10, 1), ended_on: Date.new(2026, 10, 10),
                     hours: 1, cost_usd: 0, revenue_usd: 0, stuck: "막힘", quit_signal: "신호" }.merge(over))
  end

  test "valid minimal submission gets a token and is pending" do
    s = build
    assert s.save, s.errors.full_messages.inspect
    assert s.token.present?
    assert_equal "pending", s.status
    assert_equal 10, s.days
  end

  test "rejects missing numbers, bad links, end before start" do
    assert_not build(hours: nil).valid?
    assert_not build(url: "http://x.com").valid?
    assert_not build(proof_url: "ftp://x").valid?
    assert_not build(ended_on: Date.new(2026, 9, 1)).valid?
    assert build(url: "", proof_url: nil).valid?
  end

  test "percentile counts the archive plus approved submissions only" do
    build(hours: 9999, status: "approved").save!
    build(hours: 9999).save! # pending: 비교 기준에 들어가지 않는다
    assert_equal Idea.all.size + 1, Submission.pool.size
    assert_equal 100, build(hours: 1_000_000).percentile(:hours)
    assert_equal 100, build(hours: 9999).percentile(:hours) # 같은 값은 "이하"로 센다
    assert_operator build(hours: 0).percentile(:hours), :<, 50
  end
end
