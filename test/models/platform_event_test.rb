require "test_helper"

class PlatformEventTest < ActiveSupport::TestCase
  test "장애 제목에서 리전을 읽는다" do
    {
      "Storage uploads failing in us-east-1" => [ "us-east-1" ],
      "Project creation errors ap-ne1" => [ "ap-northeast-1" ],
      "Supavisor connection disruptions in EU West 1 (Ireland)" => [ "eu-west-1" ],
      "Errors in us-east-1 and eu-central-1" => [ "us-east-1", "eu-central-1" ],
      "Logs degraded in multiple regions" => [],
      "Intermittent latency in Eastern US" => [],
      "Project lifecycle operation errors in the EU region" => []
    }.each { |title, regions| assert_equal regions, PlatformEvent.new(title:).regions, title }
  end
end
