# frozen_string_literal: true

class User < ApplicationRecord
  attr_reader :password

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 8 }
  validate :password_complexity

  normalizes :email, with: -> (email) { email.strip.downcase } 

  class << self
    private

    def pepper
      @pepper ||= Rails.application.credentials.dig(:argon2, :pepper)
    end
  end

  def password=(raw)
    @password = raw
    self.password_digest = Argon2::Password.create(raw, secret: self.class.send(:pepper))
  end

  private

  def password_complexity
    errors.add(:password, "must include an uppsercase letter") if !password.match?(/[A-Z]/)
    errors.add(:password, "must include a lowercase letter")   if !password.match?(/[a-z]/)
    errors.add(:password, "must include a digit")              if !password.match?(/\d/)
    errors.add(:password, "must include a special character")  if !password.match?(/[^A-Za-z0-9]/)
  end
end
