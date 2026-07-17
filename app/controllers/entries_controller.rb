class EntriesController < ApplicationController
  before_action :set_home
  before_action :set_entry, only: %i[show]
  before_action :set_items, only: %i[new create]

  def new
    @entry = @home.entries.build(occurred_on: Date.current)
    @cost = nil
  end

  def create
    @entry = @home.entries.build(entry_params)
    @entry.created_by_user = Current.user
    @cost = submitted_cost.presence
    assign_item
    assign_cost

    if @entry.errors.empty? && @entry.save
      redirect_to home_entry_path(@home, @entry)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  private

  def set_home
    @home = current_account.homes.find(params[:home_id])
  end

  def set_entry
    @entry = @home.entries.find(params[:id])
  end

  def set_items
    @items = @home.items.order(:name)
  end

  def entry_params
    params.require(:entry).permit(:entry_type, :title, :occurred_on, :description, :contractor_name, attachments: [])
  end

  def submitted_item_id
    params.dig(:entry, :item_id).presence
  end

  def assign_item
    return if submitted_item_id.blank?

    @entry.item = @home.items.find_by(id: submitted_item_id)
    @entry.errors.add(:item, "must belong to this home") if @entry.item.blank?
  end

  def submitted_cost
    params.dig(:entry, :cost).to_s.strip
  end

  def assign_cost
    return if submitted_cost.blank?

    @entry.cost_cents = normalized_cost_cents
    @cost = formatted_cost
  rescue ArgumentError
    @entry.errors.add(:cost, "must be a valid dollar amount")
  end

  def formatted_cost
    format("%.2f", @entry.cost_cents / 100.0)
  end

  def normalized_cost_cents
    raise ArgumentError if scientific_cost_exceeds_maximum?

    dollars = BigDecimal(submitted_cost)
    raise ArgumentError unless dollars.finite? && dollars >= 0
    raise ArgumentError if dollars >= maximum_cost_dollars

    (dollars * 100).round.to_i
  end

  def maximum_cost_dollars
    (BigDecimal(Entry::MAX_COST_CENTS.to_s) + BigDecimal("0.5")) / 100
  end

  def scientific_cost_exceeds_maximum?
    match = /\A[+-]?(?<coefficient>(?:\d+(?:\.\d*)?|\.\d+))[eE]\+?(?<exponent>\d+)\z/.match(submitted_cost)
    return false if match.blank? || !match[:coefficient].match?(/[1-9]/)

    exponent = match[:exponent].sub(/\A0+/, "")
    return false if exponent.blank?

    maximum_exponent = (match[:coefficient].split(".").last.to_s.length + 8).to_s
    exponent.length > maximum_exponent.length ||
      (exponent.length == maximum_exponent.length && exponent >= maximum_exponent)
  end
end
