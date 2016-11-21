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

    {:ok, new_image} =
      %{plug: %{uploaded_file: full_path}, cfg: img.image_series.cfg}
      |> create_image_sizes

    image = Map.put(img.image, :sizes, new_image.sizes)

    img
    |> Image.changeset(:update, %{image: image})
    |> Brando.Images.Optimize.optimize(:image)
    |> Brando.repo.update!
  end

  @doc """
  Recreates all image sizes in imageseries.
  """
  @spec recreate_sizes_for(:image_series, ImageSeries.t) :: [Image.t]
  def recreate_sizes_for(:image_series, image_series_id) do
    q =
      from is in ImageSeries,
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
  Put `size_cfg` as ̀size_key` in `image_series`.
  """
  @spec put_size_cfg(ImageSeries.t, String.t, Brando.Type.ImageConfig.t) :: :ok
  def put_size_cfg(image_series, size_key, size_cfg) do
    size_key = is_atom(size_key) && Atom.to_string(size_key) || size_key

    cfg = image_series.cfg

    cfg =
      if Map.has_key?(cfg.sizes[size_key], "portrait") do
        put_in(cfg.sizes[size_key], size_cfg)
      else
        if Map.has_key?(size_cfg, "portrait") do
          put_in(cfg.sizes[size_key], size_cfg)
        else
          put_in(cfg.sizes[size_key]["size"], size_cfg)
        end
      end

    image_series
    |> ImageSeries.changeset(:update, %{cfg: cfg})
    |> Brando.repo.update!

    recreate_sizes_for(:image_series, image_series.id)
  end

  @doc """
  Delete all images depending on imageserie `series_id`
  """
  @spec delete_images_for(:image_series, integer) :: :ok
  def delete_images_for(:image_series, series_id) do
    images = Brando.repo.all(
      from i in Image,
        where: i.image_series_id == ^series_id
    )

    for img <- images do
      delete_original_and_sized_images(img, :image)
      Brando.repo.delete!(img)
    end

    :ok
  end

  @doc """
  Delete all imageseries dependant on `category_id`
  """
  @spec delete_series_for(:image_category, integer) :: [ImageSeries.t | no_return]
  def delete_series_for(:image_category, category_id) do
    image_series = Brando.repo.all(
      from m in ImageSeries,
        where: m.image_category_id == ^category_id
    )

    for is <- image_series do
      delete_images_for(:image_series, is.id)
      Brando.repo.delete!(is)
    end
  end
end
