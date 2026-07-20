class SearchesController < ApplicationController
  def show
    @home = current_account.homes.find(params[:home_id])
    @results = HomeSearch.new(home: @home, query: params[:q]).results
  end
end
