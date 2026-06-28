# frozen_string_literal: true

class Admin::SessionsController < ApplicationController
  before_action :redirect_if_admin, only: [ :new, :create ]

  rate_limit to: 10,
             only: :create,
             within: 3.minutes,
             with: -> { redirect_to admin_new_session_path, alert: t("flash.sessions.rate_limited") }

  layout "admin_auth"

  def new
  end

  def create
    user = User.authenticate(email: params[:email], password: params[:password])
    if user&.admin?
      sign_in(user)
      redirect_to admin_root_path
    else
      flash.now[:alert] = t("flash.sessions.invalid")
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    sign_out
    redirect_to admin_new_session_path
  end

  private

    def redirect_if_admin
      redirect_to admin_root_path if current_user&.admin?
    end
end
