defmodule Brando.Portfolio.Admin.ImageSeriesForm do
  @moduledoc """
  A form for the ImageCategory model. See the `Brando.Form` module for more
  documentation
  """

  use Brando.Form
  alias Brando.Portfolio.ImageCategory
  alias Brando.Portfolio.ImageSeries

  @doc false
  def get_categories() do
    categories =
      ImageCategory
      |> ImageCategory.with_image_series_and_images
      |> Brando.repo.all

    for cat <- categories, do: [value: cat.id, text: cat.name]
  end

  form "imageseries", [model: ImageSeries, helper: :admin_portfolio_image_series_path,
                       class: "grid-form"] do
    fieldset do
      field :image_category_id, :radio, [choices: &__MODULE__.get_categories/0]
    end
    field :name, :text
    field :slug, :text, [slug_from: :name]
    field :data, :textarea, [required: false]
    submit :save, [class: "btn btn-success"]
  end
end
