class HomesController < ApplicationController
  def index
    @homes = current_account.homes.order(:name)
  end

  def new
    @home = current_account.homes.build
  end

  def create
    @home = current_account.homes.build(home_params)

    if @home.save
      redirect_to home_path(@home)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @home = current_account.homes.find(params[:id])
    @timeline_entries = @home.entries.order(occurred_on: :desc, id: :desc)
  end

  private

  def home_params
    params.require(:home).permit(:name, :address, :home_type)
  end
end
