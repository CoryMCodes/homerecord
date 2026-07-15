class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
    @user = User.new
  end

  def create
    @user = User.create_with_default_account!(registration_params)
    start_new_session_for @user
    redirect_to homes_path
  rescue ActiveRecord::RecordInvalid => error
    @user = error.record.is_a?(User) ? error.record : User.new(registration_params)
    flash.now[:alert] = "Please check your signup details."
    render :new, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotUnique
    @user = User.new(registration_params)
    @user.errors.add(:email_address, "has already been taken")
    flash.now[:alert] = "Please check your signup details."
    render :new, status: :unprocessable_entity
  end

  private

  def registration_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
