defmodule Brando.Portfolio.Admin.ImageSeriesController do
  @moduledoc """
  Controller for the Brando ImageSeries module.
  """

  use Brando.Web, :controller
  use Brando.Sequence,
    [:controller, [model: Brando.Portfolio.Image,
                   filter: &Brando.Portfolio.Image.for_series_id/1]]

  alias Brando.Portfolio.Image
  alias Brando.Portfolio.ImageSeries
  alias Brando.Portfolio.Utils

  import Brando.Plug.HTML
  import Brando.Plug.I18n

  import Brando.Portfolio.Gettext
  import Brando.Utils, only: [helpers: 1]
  import Brando.Utils.Model, only: [put_creator: 2]
  import Ecto.Query

  plug :put_section, "portfolio"
  plug :put_admin_locale, Brando.Portfolio.Gettext

  @doc false
  def new(conn, %{"id" => category_id}) do
    changeset =
      ImageSeries
      |> struct
      |> Map.put(:image_category_id, String.to_integer(category_id))
      |> ImageSeries.changeset(:create)

    conn
    |> assign(:page_title, gettext("New image series"))
    |> assign(:changeset, changeset)
    |> render(:new)
  end

  @doc false
  def create(conn, %{"imageseries" => image_series}) do
    changeset =
      %ImageSeries{}
      |> put_creator(Brando.Utils.current_user(conn))
      |> ImageSeries.changeset(:create, image_series)

    case Brando.repo.insert(changeset) do
      {:ok, _} ->
        conn
        |> put_flash(:notice, gettext("Image series created"))
        |> redirect(to: helpers(conn).admin_portfolio_image_path(conn, :index))
      {:error, changeset} ->
        conn
        |> assign(:page_title, gettext("New image series"))
        |> assign(:image_series, image_series)
        |> assign(:changeset, changeset)
        |> put_flash(:error, gettext("Errors in form"))
        |> render(:new)
    end
  end

  @doc false
  def edit(conn, %{"id" => id}) do
    changeset =
      ImageSeries
      |> Brando.repo.get_by!(id: id)
      |> ImageSeries.changeset(:update)

    conn
    |> assign(:page_title, gettext("Edit image series"))
    |> assign(:changeset, changeset)
    |> assign(:id, id)
    |> render(:edit)
  end

  @doc false
  def update(conn, %{"imageseries" => image_series, "id" => id}) do
    changeset =
      ImageSeries
      |> Brando.repo.get_by!(id: id)
      |> ImageSeries.changeset(:update, image_series)

    case Brando.repo.update(changeset) do
      {:ok, _} ->
        conn
        |> put_flash(:notice, gettext("Image series updated"))
        |> redirect(to: helpers(conn).admin_portfolio_image_path(conn, :index))
      {:error, changeset} ->
        conn
        |> assign(:page_title, gettext("Edit image series"))
        |> assign(:image_series, image_series)
        |> assign(:changeset, changeset)
        |> assign(:id, id)
        |> put_flash(:error, gettext("Errors in form"))
        |> render(:edit)
    end
  end

  @doc false
  def configure(conn, %{"id" => series_id}) do
    data = Brando.repo.get_by!(ImageSeries, id: series_id)
    {:ok, cfg} = Brando.Type.ImageConfig.dump(data.cfg)

    changeset =
      data
      |> Map.put(:cfg, cfg)
      |> ImageSeries.changeset(:update)

    conn
    |> assign(:page_title, gettext("Configure image series"))
    |> assign(:changeset, changeset)
    |> assign(:id, series_id)
    |> render(:configure)
  end

  @doc false
  def configure_patch(conn, %{"imageseriesconfig" => form_data, "id" => id}) do
    changeset =
      ImageSeries
      |> Brando.repo.get_by!(id: id)
      |> ImageSeries.changeset(:update, form_data)

    case Brando.repo.update(changeset) do
      {:ok, updated_image_series} ->
        # recreate image sizes
        Utils.recreate_sizes_for_image_series(updated_image_series.id)

        conn
        |> put_flash(:notice, gettext("Image series configured"))
        |> redirect(to: helpers(conn).admin_portfolio_image_path(conn, :index))
      {:error, changeset} ->
        conn
        |> assign(:page_title, gettext("Configure image series"))
        |> assign(:image_series, form_data)
        |> assign(:changeset, changeset)
        |> assign(:id, id)
        |> put_flash(:error, gettext("Errors in form"))
        |> render(:edit)
    end
  end

  @doc false
  def upload(conn, %{"id" => id}) do
    series =
      ImageSeries
      |> preload([:image_category, :images])
      |> Brando.repo.get_by!(id: id)

    conn
    |> assign(:page_title, gettext("Upload images"))
    |> assign(:series, series)
    |> render(:upload)
  end

  @doc false
  def upload_post(conn, %{"id" => id} = params) do
    series =
      ImageSeries
      |> preload([:image_category, :images])
      |> Brando.repo.get_by!(id: id)

    opts = Map.put(%{}, "image_series_id", series.id)
    cfg = series.cfg || Brando.config(Brando.Images)[:default_config]
    {:ok, image} = Image.check_for_uploads(params, Brando.Utils.current_user(conn), cfg, opts)

    render(conn, :upload_post, image: image)
  end

  @doc false
  def delete_confirm(conn, %{"id" => id}) do
    image_series =
      ImageSeries
      |> preload([:image_category, :images, :creator])
      |> Brando.repo.get_by!(id: id)

    conn
    |> assign(:page_title, gettext("Confirm deletion"))
    |> assign(:record, image_series)
    |> render(:delete_confirm)
  end

  @doc false
  def delete(conn, %{"id" => id}) do
    image_series = Brando.repo.get_by!(ImageSeries, id: id)
    Utils.delete_dependent_images_for_image_series(image_series.id)
    Brando.repo.delete!(image_series)

    conn
    |> put_flash(:notice, gettext("Image series deleted"))
    |> redirect(to: helpers(conn).admin_portfolio_image_path(conn, :index))
  end
end
