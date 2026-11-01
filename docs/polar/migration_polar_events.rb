# 복사 위치: db/migrate/YYYYMMDDHHMMSS_create_polar_events.rb
# 파일명 앞에 타임스탬프 붙이기: bin/rails generate migration CreatePolarEvents
# (그러면 빈 파일 생성됨 — 이 내용으로 교체)

class CreatePolarEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :polar_events do |t|
      t.string :webhook_id, null: false, index: { unique: true }  # 중복 방지
      t.string :event_type, null: false
      t.json   :payload,    default: {}
      t.timestamps
    end
  end
end
