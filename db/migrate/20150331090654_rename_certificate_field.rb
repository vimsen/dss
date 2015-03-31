class RenameCertificateField < ActiveRecord::Migration
  def change
    rename_column :energy_efficiency_certificates, :type, :cert_type
  end
end
