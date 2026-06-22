# frozen_string_literal: true

class UsersController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      # TODO
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

    def user_params
      params.expect(user: [:email, :password])
    end
end
