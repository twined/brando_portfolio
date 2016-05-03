defmodule <%= application_module %>.Portfolio.ImageCategoryController do
  use <%= application_module %>.Web, :controller

  import Brando.Plug.HTML

  alias <%= application_module %>.Portfolio.{
    FrontpagePhoto,
    ImageCategory,
    ImageSeries,
    Image,
  }

  def index(conn, _params) do
    categories = Repo.all(
      from c in ImageCategory,
        order_by: c.inserted_at
    )

    frontpage_photos = Repo.all(
      from fp in FrontpagePhoto,
        order_by: fp.inserted_at
    )

    frontpage_photo = if frontpage_photos == [] do
      nil
    else
      frontpage_photos
      |> Enum.random
    end

    conn
    |> assign(:page_title, "Portfolio")
    |> render("index.html", %{categories: categories, frontpage_photo: frontpage_photo})
  end

  def show(conn, %{"category_slug" => category_slug}) do
    image_query = from i in Image,
      select: %{
        image: i.image,
        image_series_id: i.image_series_id
      },
      order_by: [desc: i.cover, asc: i.sequence, desc: i.inserted_at]

    categories = Repo.all(
      from c in ImageCategory,
        order_by: c.inserted_at
    )
    category = Enum.find(categories, fn(c) -> c.slug == category_slug end)

    image_series = Repo.all(
      from is in ImageSeries,
        where: is.image_category_id == ^category.id,
        preload: [images: ^image_query],
        order_by: [asc: is.sequence, desc: is.inserted_at]
    )

    conn
    |> put_section("portfolio")
    |> assign(:page_title, category.name)
    |> render("show.html", %{categories: categories, category: category, image_series: image_series})
  end

  def latest(conn, _params) do
    image_query = from i in Image,
      select: %{
        image: i.image,
        image_series_id: i.image_series_id
      },
      order_by: [desc: i.cover, asc: i.sequence, desc: i.inserted_at]

    categories = Repo.all(
      from c in ImageCategory,
        order_by: c.inserted_at
    )

    latest_series = Repo.all(
      from is in ImageSeries,
        order_by: is.inserted_at,
        preload: [:image_category],
        preload: [images: ^image_query],
        limit: 20
    )

    conn
    |> put_section("portfolio")
    |> assign(:page_title, "Latest")
    |> render("latest.html", %{categories: categories, latest_series: latest_series})
  end
end
