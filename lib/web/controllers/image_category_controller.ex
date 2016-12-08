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

  alias Brando.Portfolio
  alias Brando.Portfolio.{ImageCategory, ImageSeries}

  import Ecto.Query
  import Brando.Plug.HTML
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
  def create(conn, %{"imagecategory" => data}) do
    user = current_user(conn)
    case Portfolio.create_category(data, user) do
      {:ok, _} ->
        conn
        |> put_flash(:notice, gettext("Image category created"))
        |> redirect(to: helpers(conn).admin_portfolio_image_path(conn, :index))

      {:error, changeset} ->
        conn = put_flash(conn, :error, gettext("Errors in form"))
        render conn, :new, [
          page_title:    gettext("New image category"),
          imagecategory: data,
          changeset:     changeset
        ]
    end
  end

  @doc false
  def edit(conn, %{"id" => id}) do
    changeset =
      ImageCategory
      |> Brando.repo.get!(id)
      |> ImageCategory.changeset(:update)

    render conn, :edit, [
      id:         id,
      page_title: gettext("Edit image category"),
      changeset:  changeset
    ]
  end

  @doc false
  def update(conn, %{"imagecategory" => data, "id" => id}) do
    case Portfolio.update_category(id, data) do
      {:ok, updated_category} ->
        redir = helpers(conn).admin_portfolio_image_path(conn, :index)
        conn
        |> put_flash(:notice, gettext("Image category updated"))
        |> redirect(to: redir)
      {:propagate, updated_category} ->
        redir = helpers(conn).admin_portfolio_image_category_path(conn, :propagate_configuration,
                                                                  updated_category.id)
        conn
        |> put_flash(:notice, gettext("Image category updated"))
        |> redirect(to: redir)
      {:error, changeset} ->
        conn = put_flash(conn, :error, gettext("Errors in form"))
        render conn, :edit, [
          id:             id,
          changeset:      changeset,
          page_title:     gettext("Edit image category"),
          image_category: data
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
    case Portfolio.update_category_config(id, cfg, sizes) do
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
    user     = current_user(conn)
    category = Portfolio.get_category(id)
    series   = Portfolio.get_series_for(category_id: category.id)

    # send this off for async processing
    Task.start_link(fn ->
      Brando.UserChannel.set_progress(user, 0)

      series_count  = Enum.count(series)
      progress_step = div(100, series_count) / 100

      for s <- series do
        new_path = Path.join([category.cfg.upload_path, s.slug])
        new_cfg  = Map.put(category.cfg, :upload_path, new_path)

        s
        |> ImageSeries.changeset(:update, %{cfg: new_cfg})
        |> Brando.repo.update

        :ok = Brando.Portfolio.Utils.recreate_sizes_for(:image_series, s.id)
        Brando.UserChannel.increase_progress(user, progress_step)
      end

      orphaned_series = Portfolio.get_all_orphaned_series()

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
    orphaned_series = Portfolio.get_all_orphaned_series()

    render conn, :handle_orphans, [
      page_title:      gettext("Handle orphaned image series"),
      orphaned_series: orphaned_series
    ]
  end

  @doc false
  def handle_orphans_post(conn, _params) do
    orphaned_series = Portfolio.get_all_orphaned_series()

    for s <- orphaned_series, do:
      File.rm_rf!(s)

    conn
    |> put_flash(:notice, gettext("Orphans deleted"))
    |> redirect(to: helpers(conn).admin_portfolio_image_path(conn, :index))
  end

  @doc false
  def delete_confirm(conn, %{"id" => id}) do
    record =
      ImageCategory
      |> preload([:creator, :image_series])
      |> Brando.repo.get_by!(id: id)

    render conn, :delete_confirm, [
      page_title: gettext("Confirm deletion"),
      record:     record
    ]
  end

  @doc false
  def delete(conn, %{"id" => id}) do
    Portfolio.delete_category(id)

    conn
    |> put_flash(:notice, gettext("Image category deleted"))
    |> redirect(to: helpers(conn).admin_portfolio_image_path(conn, :index))
  end
end
