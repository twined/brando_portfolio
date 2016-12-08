defmodule <%= application_module %>.Portfolio.ImageController do
  use <%= application_module %>.Web, :controller

  alias Brando.Portfolio.{
    ImageCategory,
    ImageSeries,
    Image
  }

  def show(conn, %{"category_slug" => category_slug, "series_slug" => series_slug, "id" => id}) do
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

    image = Repo.one!(
      from i in Image,
        where: i.id == ^id
    )

    conn
    |> assign(:page_title, image_series.name)
    |> render("show.html", %{
         categories: categories,
         category: category,
         all_image_series: all_image_series,
         image_series: image_series,
         image: image
       })
  end
end
