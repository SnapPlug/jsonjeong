require "test_helper"

class IdeaTest < ActiveSupport::TestCase
  test "every idea has both languages, a known status and non-negative numbers" do
    assert Idea.all.any?
    Idea.all.each do |idea|
      %i[ko en].each do |locale|
        I18n.with_locale(locale) do
          assert idea.title.present?, "#{idea.slug} #{locale} title"
          assert idea.summary.present?, "#{idea.slug} #{locale} summary"
        end
      end
      assert_includes Idea::STATUSES, idea.status, idea.slug
      assert_includes Idea::BATCHES, idea.batch, idea.slug
      assert idea.hours >= 0 && idea.cost_usd >= 0 && idea.revenue_usd >= 0, idea.slug
    end
  end

  test "every idea has a card image" do
    Idea.all.each { |idea| assert Rails.root.join("app/assets/images/ideas/#{idea.slug}.jpg").exist?, idea.slug }
  end

  test "links are https only" do
    Idea.all.filter_map(&:url).each { |url| assert url.start_with?("https://"), url }
  end

  test "slugs are unique" do
    slugs = Idea.all.map(&:slug)
    assert_equal slugs.uniq, slugs
  end

  test "totals add up the cards" do
    t = Idea.totals
    assert_equal Idea.all.size, t[:count]
    assert_in_delta Idea.all.sum(&:hours), t[:hours]
    assert_equal Idea.all.sum(&:cost_usd), t[:cost_usd]
    assert_equal Idea.all.sum(&:revenue_usd), t[:revenue_usd]
  end

  test "an idea without an end date is ongoing" do
    idea = Idea.all.find { |i| i.ended_on.nil? }
    assert idea.ongoing?
    refute Idea.all.find(&:ended_on).ongoing?
  end

  test "find raises for an unknown slug" do
    assert_equal "workoutbell", Idea.find("workoutbell").slug
    assert_raises(ActiveRecord::RecordNotFound) { Idea.find("nope") }
  end

  test "retro needs both language files" do
    assert Idea.find("workoutbell").retro?
    refute Idea.find("block-game").retro?
  end
end
