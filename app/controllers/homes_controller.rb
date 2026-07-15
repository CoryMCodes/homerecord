class HomesController < ApplicationController
  def index
    @homes = current_account.homes.order(:name)
  end

  def show
    @home = current_account.homes.find(params[:id])
  end
end
