defmodule Brando.Portfolio.Admin.ImageController do
  @moduledoc """
  Controller for the Brando ImageCategory module.
  """

  use Brando.Web, :controller

  alias Brando.Portfolio
  alias Brando.Portfolio.Image
  alias Brando.Portfolio.ImageCategory

  import Brando.Plug.HTML
  import Brando.Portfolio.Gettext
  import Brando.Images.Utils

  plug :put_section, "portfolio"

  @doc """
  Main view of our portfolio. Shows categories, series and images.
  """
  def index(conn, _params) do
    categories = Portfolio.get_categories_with_series_and_images()

    render conn, :index, [
      page_title: gettext("Index - images"),
      categories: categories
    ]
  end

  @doc false
  def delete_selected(conn, %{"ids" => ids}) do
    Portfolio.delete_images(ids)
    render conn, :delete_selected, ids: ids
  end

  @doc false
  def mark_as_cover(conn, %{"ids" => ids, "action" => action}) do
    action? = action == "1" && true || false

    Portfolio.mark_as_cover(ids, action?)

    render conn, :mark_as_cover, [
      ids:    ids,
      action: action
    ]
  end

  @doc false
  def set_properties(conn, %{"id" => id, "form" => params}) do
    image = Brando.repo.get!(Image, id)

    new_data =
      Enum.reduce(params, image.image,
                  &Map.put(&2, String.to_atom(elem(&1, 0)), elem(&1, 1)))

    Portfolio.update_image(image, %{"image" => new_data})

    render conn, :set_properties, [
      id:    id,
      attrs: params
    ]
  end
end
