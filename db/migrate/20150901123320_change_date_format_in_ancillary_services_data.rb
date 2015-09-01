class ChangeDateFormatInAncillaryServicesData < ActiveRecord::Migration
  def up
    change_column :ancillary_services_data, :date, :date
  end

  def down
    change_column :ancillary_services_data, :date, :datetime
  end
end
