# frozen_string_literal: true

class Session < ApplicationRecord
  has_secure_token :token

  belongs_to :user

  normalizes :user_agent,
             apply_to_nil: true,
             with: ->(value) { value.presence || "Unknown" }

  def refresh!
    if expired?
      destroy!
      nil
    else
      touch
      self
    end
  end

  private

    IDLE_TIMEOUT = 15.minutes
    ABSOLUTE_TIMEOUT = 30.minutes

    def expired?
      return true if updated_at < IDLE_TIMEOUT.ago
      return true if created_at < ABSOLUTE_TIMEOUT.ago

      false
    end
end
