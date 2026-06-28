# frozen_string_literal: true

class SessionsController < ApplicationController
  before_action :redirect_if_authenticated, only: [ :new, :create ]

  rate_limit to: 10,
             only: :create,
             within: 3.minutes,
             with: -> { redirect_to new_session_path, alert: t("flash.sessions.rate_limited") }

  layout "auth"

  def create
    user = User.authenticate(
      email: params[:email],
      password: params[:password]
    )
    if user&.customer?
      sign_in(user)
      redirect_to root_path
    else
      flash.now[:alert] = t("flash.sessions.invalid")
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    sign_out
    redirect_to new_session_path
  end
end
