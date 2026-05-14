class Subscriber < ApplicationRecord
  STATUSES = %w[pending synced failed].freeze

  normalizes :email, with: ->(e) { e.to_s.strip.downcase }

  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, inclusion: { in: STATUSES }
  validates :source, presence: true

  def mark_synced!
    update!(status: "synced", beehiiv_synced_at: Time.current)
  end

  def mark_failed!
    update!(status: "failed")
  end
end
