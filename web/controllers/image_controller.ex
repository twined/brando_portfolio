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

  @doc false
  def index(conn, _params) do
    # show images by tabbed category, then series.
    categories =
      ImageCategory
      |> ImageCategory.with_image_series_and_images
      |> Brando.repo.all

    conn
    |> assign(:page_title, gettext("Index - images"))
    |> assign(:categories, categories)
    |> render(:index)
  end

  @doc false
  def delete_selected(conn, %{"ids" => ids}) do
    q = from m in Image, where: m.id in ^ids
    records = Brando.repo.all(q)
    for record <- records do
      delete_original_and_sized_images(record, :image)
    end
    Brando.repo.delete_all(q)
    render(conn, :delete_selected, ids: ids)
  end

  @doc false
  def mark_as_cover(conn, %{"ids" => ids}) do
    id = List.first(ids)
    image = Brando.repo.get!(Image, id)

    from(i in Image, where: i.image_series_id == ^image.image_series_id)
    |> Brando.repo.update_all(set: [cover: false])

    image
    |> Ecto.Changeset.change(cover: true)
    |> Brando.repo.update!
    render(conn, :mark_as_cover, id: id)
  end

  @doc false
  def set_properties(conn, %{"id" => id, "form" => form}) do
    image = Brando.repo.get!(Image, id)

    new_data =
      Enum.reduce form, image.image, fn({attr, val}, acc) ->
        Map.put(acc, String.to_atom(attr), val)
      end

    image
    |> Image.changeset(:update, %{"image" => new_data})
    |> Brando.repo.update!

    render(conn, :set_properties, id: id, attrs: form)
  end
end
