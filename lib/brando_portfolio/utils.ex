defmodule Brando.Portfolio.Utils do
  import Ecto.Query, only: [from: 2]
  import Brando.Images.Utils, only: [
    check_image_paths: 2,
    create_image_sizes: 1,
    delete_original_and_sized_images: 2,
    media_path: 1,
    delete_sized_images: 1
  ]

  alias Brando.Portfolio.ImageSeries
  alias Brando.Portfolio.Image

  @doc """
  Deletes all image's sizes and recreates them.
  """
  @spec recreate_sizes_for(:image, Image.t) :: Image.t | no_return
  def recreate_sizes_for(:image, img) do
    img       = Brando.repo.preload(img, :image_series)
    img       = put_in(img.image.optimized, false)
    full_path = media_path(img.image.path)

    delete_sized_images(img.image)

    {:ok, new_image} = {%{uploaded_file: full_path}, img.image_series.cfg}
                       |> create_image_sizes

    image = Map.put(img.image, :sizes, new_image.sizes)

    img =
      img
      |> Image.changeset(:update, %{image: image})
      |> Brando.repo.update!

    Brando.Images.Optimize.optimize(img, :image)
  end

  @doc """
  Recreates all image sizes in imageseries.
  """
  @spec recreate_sizes_for(:image_series, ImageSeries.t) :: [Image.t]
  def recreate_sizes_for(:image_series, image_series_id) do
    q = from is in ImageSeries,
          preload: :images,
            where: is.id == ^image_series_id

    image_series = Brando.repo.one!(q)

    # check if the paths have changed. if so, reload series
    image_series =
      case check_image_paths(Image, image_series) do
        :changed   -> Brando.repo.one!(q)
        :unchanged -> image_series
      end

    for image <- image_series.images, do:
      recreate_sizes_for(:image, image)
  end

  @doc """
  Put `size_cfg` as ̀size_key` in `image_series`
  """
  @spec put_size_cfg(ImageSeries.t, String.t, Map.t) :: [Image.t]
  def put_size_cfg(image_series, size_key, size_cfg) do
    image_series = put_in(image_series.cfg.sizes[size_key]["size"], size_cfg)
    Brando.repo.update!(image_series)
    recreate_sizes_for(:image_series, image_series.id)
  end

  @doc """
  Delete all images depending on imageserie `series_id`
  """
  @spec delete_dependent_images_for(:image_series, Integer.t) :: no_return
  def delete_dependent_images_for(:image_series, series_id) do
    images = Brando.repo.all(
      from i in Image,
        where: i.image_series_id == ^series_id
    )

    for img <- images do
      delete_original_and_sized_images(img, :image)
      Brando.repo.delete!(img)
    end
  end

  @doc """
  Delete all imageseries dependant on `category_id`
  """
  @spec delete_image_series_depending_on_category(Integer.t) :: no_return
  def delete_image_series_depending_on_category(category_id) do
    image_series = Brando.repo.all(
      from m in ImageSeries,
        where: m.image_category_id == ^category_id
    )

    for is <- image_series do
      delete_dependent_images_for(:image_series, is.id)
      Brando.repo.delete!(is)
    end
  end
end
