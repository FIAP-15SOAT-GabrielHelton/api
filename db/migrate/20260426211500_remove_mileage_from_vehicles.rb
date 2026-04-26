class RemoveMileageFromVehicles < ActiveRecord::Migration[8.0]
  def change
    remove_column :vehicles, :mileage, :integer, default: 0, null: false
  end
end
