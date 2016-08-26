namespace :db do
  desc "TODO"
  task backup_to_initdata: :environment do
    puts "My environment id #{Rails.env}"
    FileUtils.rm_rf(Dir.glob('db/initdata/*'))

    Rails.application.eager_load!

    ActiveRecord::Base.descendants.each do |t|
      CSV.open("db/initdata/#{t}.csv", "wb") do |csv|
        csv << t.attribute_names
        t.all.each do |row|
          csv << row.attributes.values
        end
      end
    end
  end
end
