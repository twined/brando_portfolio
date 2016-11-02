defmodule Brando.Portfolio.Admin.ImageCategoryController do
  @moduledoc """
  Controller for the Brando ImageCategory module.
  """

  use Brando.Web, :controller
  use Brando.Sequence, [
    :controller, [
      schema: Brando.Portfolio.ImageSeries,
      filter: &Brando.Portfolio.ImageSeries.by_category_id/1
    ]
  ]

  alias Brando.Portfolio.{ImageCategory, ImageSeries}

  import Ecto.Query
  import Brando.Plug.HTML
  import Brando.Utils, only: [helpers: 1]
  import Brando.Utils.Schema, only: [put_creator: 2]
  import Brando.Portfolio.Gettext

  plug :put_section, "portfolio"
  plug :scrub_params, "imagecategory" when action in [:create, :update]

  @doc false
  def new(conn, _params) do
    changeset = ImageCategory.changeset(%ImageCategory{}, :create)

    render conn, :new, [
      page_title: gettext("New image category"),
      changeset:  changeset
    ]
  end

  @doc false
  def create(conn, %{"imagecategory" => imagecategory}) do
    changeset = %ImageCategory{}
                |> put_creator(Brando.Utils.current_user(conn))
                |> ImageCategory.changeset(:create, imagecategory)

    case Brando.repo.insert(changeset) do
      {:ok, _} ->
        conn
        |> put_flash(:notice, gettext("Image category created"))
        |> redirect(to: helpers(conn).admin_portfolio_image_path(conn, :index))

      {:error, changeset} ->
        conn = put_flash(conn, :error, gettext("Errors in form"))
        render conn, :new, [
          page_title:    gettext("New image category"),
          imagecategory: imagecategory,
          changeset:     changeset
        ]
    end
  end

  @doc false
  def edit(conn, %{"id" => id}) do
    changeset = ImageCategory
                |> Brando.repo.get!(id)
                |> ImageCategory.changeset(:update)

    render conn, :edit, [
      id:         id,
      page_title: gettext("Edit image category"),
      changeset:  changeset
    ]
  end

  @doc false
  def update(conn, %{"imagecategory" => image_category, "id" => id}) do
    changeset = ImageCategory
                |> Brando.repo.get_by!(id: id)
                |> ImageCategory.changeset(:update, image_category)

    case Brando.repo.update(changeset) do
      {:ok, updated_record} ->
        # We have to check this here, since the changes have not
        # yet been stored when we check validate_paths()
        redirection =
          if Ecto.Changeset.get_change(changeset, :slug) do
            helpers(conn).admin_portfolio_image_category_path(
              conn,
              :propagate_configuration,
              updated_record.id
            )
          else
            helpers(conn).admin_portfolio_image_path(conn, :index)
        end

        conn
        |> put_flash(:notice, gettext("Image category updated"))
        |> redirect(to: redirection)

      {:error, changeset} ->
        conn = put_flash(conn, :error, gettext("Errors in form"))
        render conn, :edit, [
          id:             id,
          changeset:      changeset,
          page_title:     gettext("Edit image category"),
          image_category: image_category
        ]
    end
  end

  @doc false
  def configure(conn, %{"id" => category_id}) do
    category = Brando.repo.get_by!(ImageCategory, id: category_id)

    render conn, :configure, [
      page_title: gettext("Configure image category"),
      category:   category,
      id:         category_id
    ]
  end

  @doc false
  def configure_patch(conn, %{"config" => cfg, "sizes" => sizes, "id" => id}) do
    record            = Brando.repo.get_by!(ImageCategory, id: id)
    sizes             = Brando.Images.Utils.fix_size_cfg_vals(sizes)

    allowed_mimetypes = String.split(cfg["allowed_mimetypes"], ", ")
    default_size      = cfg["default_size"]
    size_limit        = String.to_integer(cfg["size_limit"])
    upload_path       = cfg["upload_path"]

    new_cfg = Map.merge(record.cfg, %{
      allowed_mimetypes: allowed_mimetypes,
      default_size:      default_size,
      size_limit:        size_limit,
      upload_path:       upload_path,
      sizes:             sizes
    })

    cs = ImageCategory.changeset(record, :update, %{cfg: new_cfg})

    case Brando.repo.update(cs) do
      {:ok, _} ->
        conn
        |> put_flash(:notice, gettext("Configuration updated"))
        |> redirect(to: helpers(conn).admin_portfolio_image_category_path(conn, :configure, id))

      {:error, changeset} ->
        conn = put_flash(conn, :error, gettext("Errors in form"))
        render conn, :configure, [
          id:         id,
          sizes:      sizes,
          config:     cfg,
          changeset:  changeset,
          page_title: gettext("Configure image category")
        ]
    end
  end

  @doc false
  def propagate_configuration(conn, %{"id" => id}) do
    category = Brando.repo.get(ImageCategory, id)
    user     = Brando.Utils.current_user(conn)

    series = Brando.repo.all(
      from is in ImageSeries,
        where: is.image_category_id == ^category.id
    )

    # send this off for async processing
    Task.start_link(fn ->
      Brando.UserChannel.set_progress(user, 0)

      series_count  = Enum.count(series)
      progress_step = div(100, series_count) / 100

      for s <- series do
        new_path = Path.join([category.cfg.upload_path, s.slug])
        new_cfg  = Map.put(category.cfg, :upload_path, new_path)

        ImageSeries.changeset(s, :update, %{cfg: new_cfg})
        |> Brando.repo.update

        Brando.Portfolio.Utils.recreate_sizes_for(:image_series, s.id)
        Brando.UserChannel.increase_progress(user, progress_step)
      end

      orphaned_series = get_orphans()

      msg =
        if orphaned_series != [] do
          orphans_url = Brando.helpers.admin_portfolio_image_category_path(conn, :handle_orphans)
          gettext("Category propagated, but you have orphaned series. " <>
                  "Click <a href=\"%{url}\">here</a> to verify and delete", url: orphans_url)
        else
          gettext("Category propagated!")
        end

      Brando.UserChannel.set_progress(user, 1.0)
      Brando.UserChannel.alert(user, msg)
    end)

    render conn, :propagate_configuration
  end

  @doc false
  def handle_orphans(conn, _params) do
    orphaned_series = get_orphans()

    render conn, :handle_orphans, [
      page_title:      gettext("Handle orphaned image series"),
      orphaned_series: orphaned_series
    ]
  end

  @doc false
  def handle_orphans_post(conn, _params) do
    orphaned_series = get_orphans()

    for s <- orphaned_series, do:
      File.rm_rf!(s)

    conn
    |> put_flash(:notice, gettext("Orphans deleted"))
    |> redirect(to: helpers(conn).admin_portfolio_image_path(conn, :index))
  end

  defp get_orphans do
    categories = Brando.repo.all(ImageCategory)
    series     = Brando.repo.all(ImageSeries)

    Brando.Images.Utils.get_orphaned_series(categories, series, starts_with: "images/portfolio")
  end

  @doc false
  def delete_confirm(conn, %{"id" => id}) do
    record = ImageCategory
             |> preload([:creator, :image_series])
             |> Brando.repo.get_by!(id: id)

    render conn, :delete_confirm, [
      page_title: gettext("Confirm deletion"),
      record:     record
    ]
  end

  @doc false
  def delete(conn, %{"id" => id}) do
    category = Brando.repo.get_by!(ImageCategory, id: id)
    Brando.Portfolio.Utils.delete_image_series_depending_on_category(category.id)
    Brando.repo.delete!(category)

    conn
    |> put_flash(:notice, gettext("Image category deleted"))
    |> redirect(to: helpers(conn).admin_portfolio_image_path(conn, :index))
  end
end
