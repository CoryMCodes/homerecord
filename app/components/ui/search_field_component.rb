class Ui::SearchFieldComponent < ApplicationComponent
  attr_reader :url, :value, :placeholder, :query_param, :label

  def initialize(url:, value: nil, placeholder: "Search", query_param: :q, label: "Search")
    @url = url
    @value = value
    @placeholder = placeholder
    @query_param = query_param
    @label = label
  end
end
