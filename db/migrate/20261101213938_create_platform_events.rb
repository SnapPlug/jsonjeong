class CreatePlatformEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :platform_events do |t|
      t.string :source, null: false       # vercel supabase cloudflare rails nextjs
      t.string :kind, null: false         # incident release
      t.string :external_id, null: false
      t.string :title, null: false
      t.string :status                    # 장애: investigating identified monitoring resolved · 릴리스: security minor
      t.string :url
      t.datetime :happened_at, null: false
      t.datetime :notified_at
      t.timestamps
    end
    add_index :platform_events, [ :source, :external_id ], unique: true
    add_index :platform_events, :happened_at
  end
end
