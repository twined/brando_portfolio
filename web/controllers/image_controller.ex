defmodule Brando.Portfolio.Admin.ImageController do
  @moduledoc """
  Controller for the Brando ImageCategory module.
  """

  use Brando.Web, :controller

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
    categories = ImageCategory
                 |> ImageCategory.with_image_series_and_images
                 |> Brando.repo.all

    render conn, :index, [
      page_title: gettext("Index - images"),
      categories: categories
    ]
  end

  @doc false
  def delete_selected(conn, %{"ids" => ids}) do
    q       = from m in Image, where: m.id in ^ids
    records = Brando.repo.all(q)

    for record <- records, do:
      delete_original_and_sized_images(record, :image)

    Brando.repo.delete_all(q)

    render conn, :delete_selected, ids: ids
  end

  @doc false
  def mark_as_cover(conn, %{"ids" => ids, "action" => action}) do
    id      = List.first(ids)
    image   = Brando.repo.get!(Image, id)
    action? = action == "1" && true || false

    q = from i in Image, where: i.image_series_id == ^image.image_series_id

    Brando.repo.update_all(q, set: [cover: false])

    if action?, do:
      Ecto.Changeset.change(image, cover: true) |> Brando.repo.update!

    render conn, :mark_as_cover, [
      id:     id,
      action: action
    ]
  end

  @doc false
  def set_properties(conn, %{"id" => id, "form" => params}) do
    image = Brando.repo.get!(Image, id)

    new_data =
      Enum.reduce(params, image.image, &Map.put(&2, String.to_atom(elem(&1, 0)), elem(&1, 1)))

    image
    |> Image.changeset(:update, %{"image" => new_data})
    |> Brando.repo.update!

    render conn, :set_properties, [
      id:    id,
      attrs: params
    ]
  end
end
