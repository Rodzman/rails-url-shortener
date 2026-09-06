class CreateLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :links do |t|
      t.string :original_url, null: false, limit: 2048
      t.string :slug, null: false, limit: 32
      t.integer :clicks_count, null: false, default: 0
      t.datetime :expires_at

      t.timestamps
    end
    add_index :links, :slug, unique: true
  end
end
