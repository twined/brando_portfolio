defmodule <%= application_module %>.Portfolio.ImageSeriesController do
  use <%= application_module %>.Web, :controller

  alias Brando.Portfolio.{
    ImageCategory,
    ImageSeries,
    Image
  }

  def index(conn, _params) do
    render conn, "index.html"
  end

  def show(conn, %{"category_slug" => category_slug, "series_slug" => series_slug}) do
    image_query = from i in Image,
      select: %{image: i.image, image_series_id: i.image_series_id}

    categories = Repo.all(
      from c in ImageCategory,
        order_by: c.inserted_at
    )
    category = Enum.find(categories, fn(c) -> c.slug == category_slug end)

    all_image_series = Repo.all(
      from is in ImageSeries,
        where: is.image_category_id == ^category.id,
        preload: [images: ^image_query],
        order_by: [asc: is.sequence, desc: is.inserted_at]
    )

    image_series =
      Enum.find(all_image_series, fn(is) -> is.slug == series_slug end)
      |> Repo.preload(:image_category)

    images = Repo.all(
      from i in Image,
        where: i.image_series_id == ^image_series.id,
        order_by: i.sequence
    )

    conn
    |> assign(:page_title, image_series.name)
    |> render("show.html", %{
      categories: categories, category: category,
      all_image_series: all_image_series, image_series: image_series, images: images
    })
  end
end
