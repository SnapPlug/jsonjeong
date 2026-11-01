# 복사 위치: db/migrate/YYYYMMDDHHMMSS_create_portone_tables.rb
# 생성: bin/rails generate migration CreatePortoneTables

class CreatePortoneTables < ActiveRecord::Migration[8.0]
  def change
    # 웹훅 이벤트 로그 (중복 방지 + 감사 로그)
    create_table :portone_events do |t|
      t.string :webhook_id, null: false, index: { unique: true }
      t.string :event_type, null: false
      t.json   :payload,    default: {}
      t.timestamps
    end

    # 결제 내역 (유저별 결제 히스토리)
    create_table :portone_payments do |t|
      t.references :user,       null: false, foreign_key: true
      t.string     :payment_id, null: false, index: { unique: true }
      t.string     :status,     null: false, default: "pending"  # pending | paid | cancelled
      t.integer    :amount
      t.string     :channel     # kakaopay | naverpay
      t.timestamps
    end

    # User 에 결제 상태 컬럼 추가
    add_column :users, :portone_paid_at,    :datetime
    add_column :users, :portone_payment_id, :string
    add_index  :users, :portone_payment_id
  end
end
