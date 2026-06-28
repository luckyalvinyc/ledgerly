# frozen_string_literal: true

class CustomerController < ApplicationController
  before_action :redirect_if_unauthenticated
  before_action :require_customer

  private

    def require_customer
      redirect_to admin_root_path if current_user&.admin?
    end
end
