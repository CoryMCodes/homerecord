class Ui::EmptyStateComponent < ApplicationComponent
  attr_reader :title, :body

  def initialize(title:, body: nil)
    @title = title
    @body = body
  end
end
