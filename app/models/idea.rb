# 아이디어 아카이브 한 칸. config/ideas.yml을 읽는 일반 Ruby 객체 — DB에 넣지 않는다.
class Idea < Data.define(:slug, :batch, :status, :started_on, :ended_on, :hours, :hours_source, :cost_usd, :revenue_usd, :url, :text)
  STATUSES = %w[active paused dropped pivoted released].freeze
  BATCHES = %w[hundred earlier].freeze

  class << self
    def all
      @all ||= YAML.load_file(Rails.root.join("config/ideas.yml"), permitted_classes: [ Date ]).map do |row|
        new(**row.slice(*%w[slug batch status started_on hours hours_source cost_usd revenue_usd url]).symbolize_keys,
            ended_on: row["ended_on"], text: row.slice("ko", "en").freeze)
      end.freeze
    end

    def find(slug)
      all.find { |idea| idea.slug == slug } or raise ActiveRecord::RecordNotFound, "idea #{slug}"
    end

    def totals(ideas = all)
      { count: ideas.size, hours: ideas.sum(&:hours), cost_usd: ideas.sum(&:cost_usd), revenue_usd: ideas.sum(&:revenue_usd) }
    end
  end

  def initialize(url: nil, ended_on: nil, **) = super

  def ongoing? = ended_on.nil?

  %w[title summary stuck human].each do |field|
    define_method(field) { text.dig(I18n.locale.to_s, field) }
  end

  # 회고글 partial 이름. ko·en 두 파일이 다 있어야 회고글이 있는 것으로 친다.
  def retro_partial = "ideas/retros/#{slug.underscore}"

  def retro?
    %w[ko en].all? { |locale| Rails.root.join("app/views/ideas/retros/_#{slug.underscore}.#{locale}.html.erb").exist? }
  end
end
