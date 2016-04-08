defmodule Brando.Portfolio.Utils do
  import Ecto.Query, only: [from: 2]
  import Brando.Images.Utils

  alias Brando.Portfolio.ImageSeries
  alias Brando.Portfolio.Image

  @doc """
  Deletes all image's sizes and recreates them.
  """
  def recreate_sizes_for_image(img) do
    img = Brando.repo.preload(img, :image_series)
    delete_sized_images(img.image)

    full_path = media_path(img.image.path)

    {:ok, new_image} =
      create_image_sizes({%{uploaded_file: full_path}, img.image_series.cfg})

    image = Map.put(img.image, :sizes, new_image.sizes)

    img
    |> Image.changeset(:update, %{image: image})
    |> Brando.repo.update!
  end

  @doc """
  Recreates all image sizes in imageseries.
  """
  def recreate_sizes_for_image_series(image_series_id) do
    image_series = Brando.repo.one!(
      from is in ImageSeries,
        preload: :images,
        where: is.id == ^image_series_id
    )
    for image <- image_series.images do
      Utils.recreate_sizes_for_image(image)
    end
  end

  @doc """
  Put `size_cfg` as ̀size_key` in `image_series`
  """
  def put_size_cfg(image_series, size_key, size_cfg) do
    image_series = put_in(image_series.cfg.sizes[size_key]["size"], size_cfg)
    Brando.repo.update!(image_series)
    recreate_sizes_for_image_series(image_series.id)
  end

  @doc """
  Delete all images depending on imageserie `series_id`
  """
  def delete_dependent_images_for_image_series(series_id) do
    images = Brando.repo.all(
      from i in Image, where: i.image_series_id == ^series_id
    )

    for img <- images do
      delete_original_and_sized_images(img, :image)
      Brando.repo.delete!(img)
    end
  end

  @doc """
  Delete all imageseries dependant on `category_id`
  """
  def delete_image_series_depending_on_category(category_id) do
    image_series = Brando.repo.all(
      from m in ImageSeries,
        where: m.image_category_id == ^category_id
    )

    for is <- image_series do
      delete_dependent_images_for_image_series(is.id)
      Brando.repo.delete!(is)
    end
  end
end
