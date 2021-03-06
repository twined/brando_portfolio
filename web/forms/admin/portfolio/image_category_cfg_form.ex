defmodule Brando.Portfolio.Admin.ImageCategoryConfigForm do
  @moduledoc """
  A form for the ImageCategory configuration model. See the `Brando.Form`
  module for more documentation
  """

  use Brando.Form
  alias Brando.Portfolio.ImageCategory

  form "imagecategoryconfig", [schema: ImageCategory,
                               helper: :admin_portfolio_image_category_path,
                               class: "grid-form"] do
    field :cfg, :textarea
    submit :save, [class: "btn btn-success"]
  end
end
