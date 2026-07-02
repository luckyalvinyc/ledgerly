# frozen_string_literal: true

module Authentication
  extend ActiveSupport::Concern

  SESSION_COOKIE = "__Host-session_token"

  included do
    helper_method :current_user
  end

  private

    def current_user
      return @current_user if defined?(@current_user)

      @current_user = current_session&.user
    end

    def current_session
      @current_session ||= Session.find_by(token: cookies.signed[SESSION_COOKIE])&.refresh!
    end

    def sign_in(user)
      session = user.sessions.create!(
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )
      cookies.signed[SESSION_COOKIE] = {
        secure: true,
        httponly: true,
        same_site: :lax,
        value: session.token
      }
    end

    def sign_out
      return if current_session.nil?

      current_session.destroy!
      cookies.delete(SESSION_COOKIE)

      @current_user = nil
      @current_session = nil
    end

    def redirect_if_unauthenticated
      redirect_to new_session_path if current_user.nil?
    end

    def redirect_if_authenticated
      redirect_to root_path if current_user.present?
    end
end
