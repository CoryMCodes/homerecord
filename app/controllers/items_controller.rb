class ItemsController < ApplicationController
  before_action :set_home
  before_action :set_item, only: %i[show edit update]

  def index
    @items = @home.items.order(:name)
  end

  def new
    @item = @home.items.build
  end

  def create
    @item = @home.items.build(item_params)

    if @item.save
      redirect_to home_item_path(@home, @item)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def edit
  end

  def update
    if @item.update(item_params)
      redirect_to home_item_path(@home, @item), status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_home
    @home = current_account.homes.find(params[:home_id])
  end

  def set_item
    @item = @home.items.find(params[:id])
  end

  def item_params
    params.require(:item).permit(:item_kind, :name, :brand, :model_number, :serial_number, :installed_on, :notes)
  end
end
