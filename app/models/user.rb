# frozen_string_literal: true

class User < ApplicationRecord
  ARGON2_PEPPER = Rails.application.credentials.dig(:argon2, :pepper)
  DUMMY_DIGEST = Argon2::Password.create(SecureRandom.hex, secret: ARGON2_PEPPER)

  attr_reader :password

  validates :email,
            presence: true,
            uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password,
            presence: true,
            length: { minimum: 8 }
  validate :password_complexity

  normalizes :email, with: ->(email) { email.strip.downcase }

  enum :role, { customer: "customer", admin: "admin" }

  has_many :sessions
  has_many :bank_accounts
  has_many :imports, through: :bank_accounts
  has_many :transactions, through: :bank_accounts

  class << self
    def authenticate(email:, password:)
      user = find_by(email:)
      digest = user.password_digest if user.present?
      digest ||= DUMMY_DIGEST
      return if !Argon2::Password.verify_password(password, digest, ARGON2_PEPPER)

      user
    end
  end

  def password=(raw)
    @password = raw
    self.password_digest = Argon2::Password.create(raw, secret: ARGON2_PEPPER)
  end

  private

  def password_complexity
    errors.add(:password, "must include an uppercase letter") if !password.match?(/[A-Z]/)
    errors.add(:password, "must include a lowercase letter")   if !password.match?(/[a-z]/)
    errors.add(:password, "must include a digit")              if !password.match?(/\d/)
    errors.add(:password, "must include a special character")  if !password.match?(/[^A-Za-z0-9]/)
  end
end
