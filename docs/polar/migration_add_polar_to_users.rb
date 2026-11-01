# 복사 위치: db/migrate/YYYYMMDDHHMMSS_add_polar_to_users.rb
# 생성: bin/rails generate migration AddPolarToUsers
# (빈 파일을 이 내용으로 교체)

class AddPolarToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :polar_subscription_id, :string
    add_column :users, :polar_status,          :string, default: "free"  # free | active | canceling | canceled
    add_column :users, :polar_access_until,    :datetime

    add_index :users, :polar_subscription_id
  end
end
