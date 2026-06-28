# frozen_string_literal: true

class Admin::BaseController < ApplicationController
  layout "admin"

  before_action :require_admin

  private

    def require_admin
      redirect_to admin_new_session_path if !current_user&.admin?
    end
end
