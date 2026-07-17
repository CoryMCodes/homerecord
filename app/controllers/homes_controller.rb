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
    @entry_type_filter = filtered_entry_type
    @timeline_filter_items = timeline_filter_items
    @timeline_entries = @home.entries
    @timeline_entries = @timeline_entries.where(entry_type: @entry_type_filter) if @entry_type_filter.present?
    @timeline_entries = @timeline_entries.order(occurred_on: :desc, id: :desc)
  end

  private

  def filtered_entry_type
    params[:entry_type].presence_in(Entry::ENTRY_TYPES)
  end

  def timeline_filter_items
    [
      { label: "All", href: home_path(@home), active: @entry_type_filter.blank? },
      *Entry::ENTRY_TYPES.map do |entry_type|
        {
          label: entry_type.humanize,
          href: home_path(@home, entry_type: entry_type),
          active: @entry_type_filter == entry_type
        }
      end
    ]
  end

  def home_params
    params.require(:home).permit(:name, :address, :home_type)
  end
end
