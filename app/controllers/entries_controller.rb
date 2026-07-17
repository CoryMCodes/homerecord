class EntriesController < ApplicationController
  before_action :set_home
  before_action :set_items, only: :new

  def new
    @entry = @home.entries.build(occurred_on: Date.current)
    @cost = nil
  end

  private

  def set_home
    @home = current_account.homes.find(params[:home_id])
  end

  def set_items
    @items = @home.items.order(:name)
  end
end
