namespace :db do
  desc "TODO"
  task backup_to_initdata: :environment do
    puts "My environment id #{Rails.env}"
    FileUtils.rm_rf(Dir.glob('db/initdata/*'))

    Rails.application.eager_load!

    ActiveRecord::Base.descendants.reject do |t| 
      [DataPoint, Instance, Prosumer::HABTM_TempClusters].include? t
    end.each do |t|
      CSV.open("db/initdata/#{t}.csv", "wb") do |csv|
        csv << t.attribute_names
        all_obejcts = t.attribute_names.include?("id") ? t.all.order(id: :asc): t.all
        all_obejcts.each do |row|
          csv << row.attributes.values
        end
      end
    end
  end
end
