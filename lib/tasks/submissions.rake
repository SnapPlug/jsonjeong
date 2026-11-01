namespace :submissions do
  desc "대기 중인 제출 목록"
  task pending: :environment do
    Submission.where(status: "pending").order(:created_at).each do |s|
      puts "#{s.id}\t#{s.created_at.to_date}\t#{s.name}\t#{s.email}\t#{s.hours}h $#{s.cost_usd}→$#{s.revenue_usd}\t#{s.url}\t#{s.proof_url}"
      puts "\t막힘: #{s.stuck}\n\t신호: #{s.quit_signal}"
    end
  end

  desc "제출 승인: bin/rails submissions:approve[id]  (거절은 submissions:reject[id])"
  task :approve, [ :id ] => :environment do |_t, args|
    s = Submission.find(args.fetch(:id))
    s.update!(status: "approved")
    puts "approved #{s.id}"
    # 스레드에 던질 문장. 올리는 것은 사람이 한다.
    url = "https://jsonjeong.com#{s.locale == "en" ? "/en" : ""}/submissions/#{s.token}"
    puts I18n.with_locale(s.locale) { I18n.t("submit.share_text", name: s.name, hours: ApplicationController.helpers.work_hours(s.hours), cost: ApplicationController.helpers.usd(s.cost_usd), revenue: ApplicationController.helpers.usd(s.revenue_usd), count: Submission.pool.size) }
    puts url
  end

  task :reject, [ :id ] => :environment do |_t, args|
    Submission.find(args.fetch(:id)).update!(status: "rejected")
    puts "rejected #{args[:id]}"
  end
end
