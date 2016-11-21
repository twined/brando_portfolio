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

  plug :put_section, "portfolio"

  @doc false
  def new(conn, %{"id" => category_id}) do
    changeset =
      %ImageSeries{}
      |> Map.put(:image_category_id, String.to_integer(category_id))
      |> ImageSeries.changeset(:create)

    render conn, :new, [
      page_title: gettext("New image series"),
      changeset:  changeset
    ]
  end

  @doc false
  def create(conn, %{"imageseries" => data}) do
    case Portfolio.create_series(data, current_user(conn)) do
      {:ok, inserted_series} ->
        conn
        |> put_flash(:notice, gettext("Image series created"))
        |> redirect(to: helpers(conn).admin_portfolio_image_series_path(conn, :upload, inserted_series.id))
      {:error, changeset} ->
        conn = put_flash(conn, :error, gettext("Errors in form"))

        render conn, :new, [
          page_title:   gettext("New image series"),
          image_series: data,
          changeset:    changeset
        ]
    end
  end

  @doc false
  def edit(conn, %{"id" => id}) do
    changeset =
      ImageSeries
      |> Brando.repo.get_by!(id: id)
      |> ImageSeries.changeset(:update)

    render conn, :edit, [
      id:         id,
      changeset:  changeset,
      page_title: gettext("Edit image series"),
    ]
  end

  @doc false
  def update(conn, %{"imageseries" => data, "id" => id}) do
    case Portfolio.update_series(id, data) do
      {:ok, _} ->
        conn
        |> put_flash(:notice, gettext("Image series updated"))
        |> redirect(to: helpers(conn).admin_portfolio_image_path(conn, :index))
      {:error, changeset} ->
        conn = put_flash(conn, :error, gettext("Errors in form"))

        render conn, :edit, [
          id:           id,
          changeset:    changeset,
          image_series: data,
          page_title:   gettext("Edit image series"),
        ]
    end
  end

  @doc false
  def configure(conn, %{"id" => series_id}) do
    series = Brando.repo.get_by!(ImageSeries, id: series_id)

    series =
      if series.cfg do
        series
      else
        category = Brando.repo.get!(ImageCategory, series.image_category_id)
        Map.put(series, :cfg, category.cfg)
      end

    render conn, :configure, [
      id:         series_id,
      series:     series,
      page_title: gettext("Configure image series"),
    ]
  end

  @doc false
  def configure_patch(conn, %{"config" => cfg, "sizes" => sizes, "id" => id}) do
    case Portfolio.update_series_config(id, cfg ,sizes) do
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
    user = current_user(conn)

    # send this off for async processing
    _ = Task.start_link(fn ->
      Brando.UserChannel.set_progress(user, 0)
      :ok = Utils.recreate_sizes_for(:image_series, id)
      Brando.UserChannel.set_progress(user, 1)
      Brando.UserChannel.alert(user, gettext("Recreated sizes for image series"))
    end)

    conn
    |> redirect(to: helpers(conn).admin_portfolio_image_path(conn, :index))
  end

  @doc false
  def upload(conn, %{"id" => id}) do
    series =
      ImageSeries
      |> preload([:image_category, :images])
      |> Brando.repo.get_by!(id: id)

    render conn, :upload, [
      series:     series,
      page_title: gettext("Upload images"),
    ]
  end

  @doc false
  def upload_post(conn, %{"id" => id} = params) do
    series =
      ImageSeries
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
    image_series =
      ImageSeries
      |> preload([:image_category, :images, :creator])
      |> Brando.repo.get_by!(id: id)

    render conn, :delete_confirm, [
      record:     image_series,
      page_title: gettext("Confirm deletion"),
    ]
  end

  @doc false
  def delete(conn, %{"id" => id}) do
    {:ok, deleted_series} = Portfolio.delete_series(id)
    category_slug = deleted_series.image_category.slug

    conn
    |> put_flash(:notice, gettext("Image series deleted"))
    |> redirect(to: helpers(conn).admin_portfolio_image_path(conn, :index) <> "##{category_slug}")
  end
end
