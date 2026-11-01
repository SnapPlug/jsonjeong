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
    Submission.find(args.fetch(:id)).update!(status: "approved")
    puts "approved #{args[:id]}"
  end

  task :reject, [ :id ] => :environment do |_t, args|
    Submission.find(args.fetch(:id)).update!(status: "rejected")
    puts "rejected #{args[:id]}"
  end
end
