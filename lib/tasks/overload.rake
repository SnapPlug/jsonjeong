namespace :overload do
  desc "옛 Overload(Turso) 반출 JSON 가져오기: bin/rails overload:import[/path/turso-export.json]"
  task :import, [ :path ] => :environment do |_task, args|
    puts OverloadImport.run(args.fetch(:path))
  end
end
