class CreateClicks < ActiveRecord::Migration[8.1]
  def change
    create_table :clicks do |t|
      t.references :link, null: false, foreign_key: true
      t.string :referrer, limit: 2048
      t.string :user_agent, limit: 512
      t.string :visitor_hash, limit: 64

      t.timestamps
    end
    add_index :clicks, [ :link_id, :created_at ]
  end
end
