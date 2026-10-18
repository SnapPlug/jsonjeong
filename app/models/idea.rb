# 아이디어 아카이브 한 칸. config/ideas.yml을 읽는 일반 Ruby 객체 — DB에 넣지 않는다.
class Idea < Data.define(:slug, :batch, :status, :started_on, :ended_on, :hours, :hours_source, :cost_usd, :revenue_usd, :url, :screen, :text)
  STATUSES = %w[active paused dropped released].freeze
  BATCHES = %w[hundred earlier].freeze
  # nomads.com 카드 높이 그대로(2026-10-18 실측). 열 수는 ideas/index의 격자가 맞춘다.
  CARD_HEIGHT = "h-[calc(50vw-28px)] min-[361px]:h-[calc(50vw-42px)] min-[700px]:h-[calc(33vw-56px)] min-[1000px]:h-[calc(25vw-56px)] min-[1300px]:h-[284px]".freeze

  class << self
    def all
      @all ||= YAML.load_file(Rails.root.join("config/ideas.yml"), permitted_classes: [ Date ]).map do |row|
        new(**row.slice(*%w[slug batch status started_on hours hours_source cost_usd revenue_usd url screen]).symbolize_keys,
            ended_on: row["ended_on"], text: row.slice("ko", "en").freeze)
      end.freeze
    end

    def find(slug)
      all.find { |idea| idea.slug == slug } or raise ActiveRecord::RecordNotFound, "idea #{slug}"
    end

    # 카드 막대 그래프의 기준(가장 큰 값 = 막대 끝)
    def maxima
      { hours: all.map(&:hours).max, days: all.map(&:days).max, cost_usd: all.map(&:cost_usd).max }
    end

    def status_counts
      STATUSES.index_with { |status| all.count { |idea| idea.status == status } }.select { |_, n| n.positive? }
    end

    def totals(ideas = all)
      { count: ideas.size, hours: ideas.sum(&:hours), cost_usd: ideas.sum(&:cost_usd), revenue_usd: ideas.sum(&:revenue_usd) }
    end
  end

  def initialize(url: nil, ended_on: nil, screen: false, **) = super

  def ongoing? = ended_on.nil?

  # 검증 기간(일). 시작일과 끝난 날을 모두 센다. 진행 중이면 오늘까지.
  def days = ((ended_on || Date.current) - started_on).to_i + 1

  %w[title summary stuck human].each do |field|
    define_method(field) { text.dig(I18n.locale.to_s, field) }
  end

  # 회고글 partial 이름. ko·en 두 파일이 다 있어야 회고글이 있는 것으로 친다.
  def retro_partial = "ideas/retros/#{slug.underscore}"

  def retro?
    %w[ko en].all? { |locale| Rails.root.join("app/views/ideas/retros/_#{slug.underscore}.#{locale}.html.erb").exist? }
  end
end
