defmodule Brando.Portfolio.Admin.ImageCategoryForm do
  @moduledoc """
  A form for the ImageCategory model. See the `Brando.Form` module for more
  documentation
  """

  use Brando.Form
  alias Brando.Portfolio.ImageCategory

  form "imagecategory", [schema: ImageCategory,
                         helper: :admin_portfolio_image_category_path,
                         class: "grid-form"] do
    field :name, :text
    field :slug, :text, [slug_from: :name]
    submit :save, [class: "btn btn-success"]
  end
end
