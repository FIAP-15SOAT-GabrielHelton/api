class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers, id: :bigint do |t|
      t.integer :person_type, null: false, default: 0
      t.string :document, null: false
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone
      t.string :zip_code, null: false
      t.string :street, null: false
      t.string :number, null: false
      t.string :complement
      t.string :city, null: false
      t.string :state, null: false
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :customers, :document, unique: true
    add_index :customers, :status
  end
end
