class CreateVehicles < ActiveRecord::Migration[8.1]
  def change
    create_table :vehicles do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :license_plate, null: false
      t.string :make, null: false
      t.string :model, null: false
      t.integer :year, null: false
      t.string :color
      t.integer :mileage, null: false, default: 0
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :vehicles, :license_plate, unique: true
    add_index :vehicles, :status
  end
end
