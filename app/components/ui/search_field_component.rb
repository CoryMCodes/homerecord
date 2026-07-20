class Ui::SearchFieldComponent < ApplicationComponent
  attr_reader :url, :value, :placeholder, :query_param, :label, :turbo_frame, :form_data, :input_data, :autocomplete

  def initialize(url:, value: nil, placeholder: "Search", query_param: :q, label: "Search", turbo_frame: nil, form_data: {}, input_data: {}, autocomplete: "off")
    @url = url
    @value = value
    @placeholder = placeholder
    @query_param = query_param
    @label = label
    @turbo_frame = turbo_frame
    @form_data = form_data
    @input_data = input_data
    @autocomplete = autocomplete
  end

  def form_html_options
    {
      role: "search",
      class: "mt-8",
      data: resolved_form_data
    }
  end

  private

  def resolved_form_data
    form_data.tap do |data|
      data[:turbo_frame] = turbo_frame if turbo_frame.present?
    end
  end
end
