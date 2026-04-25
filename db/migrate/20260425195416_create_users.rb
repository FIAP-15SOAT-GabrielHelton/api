class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :bigint do |t|
      t.string :email, null: false
      t.string :name, null: false
      t.string :password_digest, null: false
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :status
  end
end
