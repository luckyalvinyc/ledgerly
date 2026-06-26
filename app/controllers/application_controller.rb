# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :current_theme

  before_action :set_no_store

  private

    def set_no_store
      return if current_user.nil?

      response.headers["Cache-Control"] = "no-store"
    end

    # "light" or "dark" when the user has overridden the OS default, else nil.
    def current_theme
      cookies[:theme].presence_in(%w[light dark])
    end

    def redirect_if_authenticated
      redirect_to root_path if current_user.present?
    end

    def redirect_if_unauthenticated
      redirect_to new_session_path if current_user.nil?
    end

    def current_user
      if defined?(@current_user)
        @current_user
      else
        @current_user = current_session.user if current_session.present?
        @current_user
      end
    end

    SESSION_COOKIE = "__Host-session_token"

    def current_session
      @current_session ||= begin
        session = Session.find_by(token: cookies.signed[SESSION_COOKIE])
        session.refresh! if session.present?
      end
    end

    def sign_in(user)
      session = user.sessions.create!(
        token: SecureRandom.urlsafe_base64(32),
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
end
