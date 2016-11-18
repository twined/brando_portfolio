defmodule Brando.Portfolio.Admin.ImageSeriesController do
  @moduledoc """
  Controller for the Brando ImageSeries module.
  """

  use Brando.Web, :controller
  use Brando.Sequence, [
    :controller, [
      schema: Brando.Portfolio.Image,
      filter: &Brando.Portfolio.Image.for_series_id/1
    ]
  ]

  alias Brando.Portfolio
  alias Brando.Portfolio.{ImageSeries, Utils}

  import Ecto.Query
  import Brando.Plug.HTML
  import Brando.Portfolio.Gettext
  import Brando.Utils, only: [helpers: 1]
  import Brando.Utils.Schema, only: [put_creator: 2]
  import Brando.Images.Utils, only: [fix_size_cfg_vals: 1]

  plug :put_section, "portfolio"

  @doc false
  def new(conn, %{"id" => category_id}) do
    changeset = ImageSeries
                |> struct
                |> Map.put(:image_category_id, String.to_integer(category_id))
                |> ImageSeries.changeset(:create)

    render conn, :new, [
      page_title: gettext("New image series"),
      changeset:  changeset
    ]
  end

  @doc false
  def create(conn, %{"imageseries" => image_series}) do
    changeset = %ImageSeries{}
                |> put_creator(Brando.Utils.current_user(conn))
                |> ImageSeries.changeset(:create, image_series)

    case Brando.repo.insert(changeset) do
      {:ok, inserted_series} ->
        conn
        |> put_flash(:notice, gettext("Image series created"))
        |> redirect(to: helpers(conn).admin_portfolio_image_series_path(conn, :upload, inserted_series.id))
      {:error, changeset} ->
        conn = put_flash(conn, :error, gettext("Errors in form"))

        render conn, :new, [
          page_title:   gettext("New image series"),
          image_series: image_series,
          changeset:    changeset
        ]
    end
  end

  @doc false
  def edit(conn, %{"id" => id}) do
    changeset = ImageSeries
                |> Brando.repo.get_by!(id: id)
                |> ImageSeries.changeset(:update)

    render conn, :edit, [
      id:         id,
      changeset:  changeset,
      page_title: gettext("Edit image series"),
    ]
  end

  @doc false
  def update(conn, %{"imageseries" => image_series, "id" => id}) do
    changeset = ImageSeries
                |> Brando.repo.get_by!(id: id)
                |> ImageSeries.changeset(:update, image_series)

    case Brando.repo.update(changeset) do
      {:ok, _} ->
        # We have to check this here, since the changes have not been stored in
        # the ImageSeries.validate_paths() when we check.
        if Ecto.Changeset.get_change(changeset, :slug) ||
           Ecto.Changeset.get_change(changeset, :image_category_id), do:
          Utils.recreate_sizes_for(:image_series, changeset.data.id)

        conn
        |> put_flash(:notice, gettext("Image series updated"))
        |> redirect(to: helpers(conn).admin_portfolio_image_path(conn, :index))
      {:error, changeset} ->
        conn = put_flash(conn, :error, gettext("Errors in form"))

        render conn, :edit, [
          id:           id,
          changeset:    changeset,
          image_series: image_series,
          page_title:   gettext("Edit image series"),
        ]
    end
  end

  @doc false
  def configure(conn, %{"id" => series_id}) do
    series = Brando.repo.get_by!(ImageSeries, id: series_id)

    render conn, :configure, [
      id:         series_id,
      series:     series,
      page_title: gettext("Configure image series"),
    ]
  end

  @doc false
  def configure_patch(conn, %{"config" => cfg, "sizes" => sizes, "id" => id}) do
    record = Brando.repo.get_by!(ImageSeries, id: id)
    sizes  = fix_size_cfg_vals(sizes)

    allowed_mimetypes = String.split(cfg["allowed_mimetypes"], ", ")
    default_size      = cfg["default_size"]
    size_limit        = String.to_integer(cfg["size_limit"])
    upload_path       = cfg["upload_path"]

    new_cfg = Map.merge(record.cfg, %{
      sizes:             sizes,
      size_limit:        size_limit,
      upload_path:       upload_path,
      default_size:      default_size,
      allowed_mimetypes: allowed_mimetypes,
    })

    cs = ImageSeries.changeset(record, :update, %{cfg: new_cfg})

    case Brando.repo.update(cs) do
      {:ok, _} ->
        conn
        |> put_flash(:notice, gettext("Configuration updated"))
        |> redirect(to: helpers(conn).admin_portfolio_image_series_path(conn, :configure, id))
      {:error, changeset} ->
        conn = put_flash(conn, :error, gettext("Errors in form"))

        render conn, :configure, [
          id:         id,
          sizes:      sizes,
          config:     cfg,
          changeset:  changeset,
          page_title: gettext("Configure image series")
        ]
      end
  end

  @doc false
  def recreate_sizes(conn, %{"id" => id}) do
    Utils.recreate_sizes_for(:image_series, id)

    conn
    |> put_flash(:notice, gettext("Recreated sizes for image series"))
    |> redirect(to: helpers(conn).admin_portfolio_image_path(conn, :index))
  end

  @doc false
  def upload(conn, %{"id" => id}) do
    series = ImageSeries
             |> preload([:image_category, :images])
             |> Brando.repo.get_by!(id: id)

    render conn, :upload, [
      series:     series,
      page_title: gettext("Upload images"),
    ]
  end

  @doc false
  def upload_post(conn, %{"id" => id} = params) do
    series = ImageSeries
             |> preload([:image_category, :images])
             |> Brando.repo.get_by!(id: id)

    cfg  = series.cfg || Brando.config(Brando.Images)[:default_config]
    opts = Map.put(%{}, "image_series_id", series.id)

    case Portfolio.check_for_uploads(params, Brando.Utils.current_user(conn), cfg, opts) do
      {:ok, image} ->
        render conn, :upload_post, image: image, status: 200, error_msg: nil
      {:error, error_msg} ->
        conn
        |> put_status(400)
        |> render(:upload_post, status: 400, error_msg: error_msg)
    end
  end

  @doc false
  def delete_confirm(conn, %{"id" => id}) do
    image_series = ImageSeries
                   |> preload([:image_category, :images, :creator])
                   |> Brando.repo.get_by!(id: id)

    render conn, :delete_confirm, [
      record:     image_series,
      page_title: gettext("Confirm deletion"),
    ]
  end

  @doc false
  def delete(conn, %{"id" => id}) do
    image_series = Brando.repo.get_by!(ImageSeries, id: id)
    Utils.delete_dependent_images_for(:image_series, image_series.id)

    # execute callbacks
    Brando.Portfolio.Callbacks.execute(:image_series, :on_delete, image_series)
    Brando.repo.delete!(image_series)

    conn
    |> put_flash(:notice, gettext("Image series deleted"))
    |> redirect(to: helpers(conn).admin_portfolio_image_path(conn, :index))
  end
end
