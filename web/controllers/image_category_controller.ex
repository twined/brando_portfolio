defmodule Brando.Portfolio.Admin.ImageCategoryController do
  @moduledoc """
  Controller for the Brando ImageCategory module.
  """

  use Brando.Web, :controller
  use Brando.Sequence,
    [:controller, [model: Brando.Portfolio.ImageSeries,
                   filter: &Brando.Portfolio.ImageSeries.by_category_id/1]]

  alias Brando.Portfolio.{ImageCategory, ImageSeries}
  alias Brando.Portfolio.Utils

  import Brando.Plug.HTML

  import Brando.Utils, only: [helpers: 1, current_user: 1]
  import Brando.Utils.Model, only: [put_creator: 2]
  import Brando.Images.Utils, only: [fix_size_cfg_vals: 1]
  import Brando.Portfolio.Gettext

  import Ecto.Query

  plug :put_section, "portfolio"
  plug :scrub_params, "imagecategory" when action in [:create, :update]

  @doc false
  def new(conn, _params) do
    changeset = ImageCategory.changeset(%ImageCategory{}, :create)

    conn
    |> assign(:page_title, gettext("New image category"))
    |> assign(:changeset, changeset)
    |> render(:new)
  end

  @doc false
  def create(conn, %{"imagecategory" => imagecategory}) do
    changeset =
      %ImageCategory{}
      |> put_creator(Brando.Utils.current_user(conn))
      |> ImageCategory.changeset(:create, imagecategory)

    case Brando.repo.insert(changeset) do
      {:ok, _} ->
        conn
        |> put_flash(:notice, gettext("Image category created"))
        |> redirect(to: helpers(conn).admin_portfolio_image_path(conn, :index))
      {:error, changeset} ->
        conn
        |> assign(:page_title, gettext("New image category"))
        |> assign(:imagecategory, imagecategory)
        |> assign(:changeset, changeset)
        |> put_flash(:error, gettext("Errors in form"))
        |> render(:new)
    end
  end

  @doc false
  def edit(conn, %{"id" => id}) do
    changeset =
      ImageCategory
      |> Brando.repo.get!(id)
      |> ImageCategory.changeset(:update)

    conn
    |> assign(:page_title, gettext("Edit image category"))
    |> assign(:changeset, changeset)
    |> assign(:id, id)
    |> render(:edit)
  end

  @doc false
  def update(conn, %{"imagecategory" => image_category, "id" => id}) do
    changeset =
      ImageCategory
      |> Brando.repo.get_by!(id: id)
      |> ImageCategory.changeset(:update, image_category)

    case Brando.repo.update(changeset) do
      {:ok, _updated_record} ->
        conn
        |> put_flash(:notice, gettext("Image category updated"))
        |> redirect(to: helpers(conn).admin_portfolio_image_path(conn, :index))
      {:error, changeset} ->
        conn
        |> assign(:page_title, gettext("Edit image category"))
        |> assign(:image_category, image_category)
        |> assign(:changeset, changeset)
        |> assign(:id, id)
        |> put_flash(:error, gettext("Errors in form"))
        |> render(:edit)
    end
  end

  @doc false
  def configure(conn, %{"id" => category_id}) do
    category = Brando.repo.get_by!(ImageCategory, id: category_id)

    conn
    |> assign(:page_title, gettext("Configure image category"))
    |> assign(:category, category)
    |> assign(:id, category_id)
    |> render(:configure)
  end

  @doc false
  def configure_patch(conn, %{"config" => cfg, "sizes" => sizes, "id" => id}) do
    record = Brando.repo.get_by!(ImageCategory, id: id)

    sizes = fix_size_cfg_vals(sizes)

    new_cfg =
      record.cfg
      |> Map.put(:allowed_mimetypes, String.split(cfg["allowed_mimetypes"], ", "))
      |> Map.put(:default_size, cfg["default_size"])
      |> Map.put(:size_limit, String.to_integer(cfg["size_limit"]))
      |> Map.put(:upload_path, cfg["upload_path"])
      |> Map.put(:sizes, sizes)

    cs = ImageCategory.changeset(record, :update, %{cfg: new_cfg})

    case Brando.repo.update(cs) do
      {:ok, _} ->
        conn
        |> put_flash(:notice, gettext("Configuration updated"))
        |> redirect(to: helpers(conn).admin_portfolio_image_path(conn, :index))
      {:error, changeset} ->
        conn
        |> assign(:page_title, gettext("Configure image category"))
        |> assign(:config, cfg)
        |> assign(:sizes, sizes)
        |> assign(:changeset, changeset)
        |> assign(:id, id)
        |> put_flash(:error, gettext("Errors in form"))
        |> render(:configure)
    end
  end

  @doc false
  def propagate_configuration(conn, %{"id" => id}) do
    category = Brando.repo.get(ImageCategory, id)

    series = Brando.repo.all(
      from is in ImageSeries,
        where: is.image_category_id == ^category.id
    )

    for s <- series do
      s
      |> ImageSeries.changeset(:update, %{cfg: category.cfg})
      |> Brando.repo.update

      Utils.recreate_sizes_for_image_series(s.id)
    end

    conn
    |> put_flash(:notice, gettext("Category propagated"))
    |> redirect(to: helpers(conn).admin_portfolio_image_path(conn, :index))
  end

  @doc false
  def delete_confirm(conn, %{"id" => id}) do
    record =
      ImageCategory
      |> preload([:creator, :image_series])
      |> Brando.repo.get_by!(id: id)

    conn
    |> assign(:page_title, gettext("Confirm deletion"))
    |> assign(:record, record)
    |> render(:delete_confirm)
  end

  @doc false
  def delete(conn, %{"id" => id}) do
    image_category = Brando.repo.get_by!(ImageCategory, id: id)
    Utils.delete_image_series_depending_on_category(image_category.id)
    Brando.repo.delete!(image_category)

    conn
    |> put_flash(:notice, gettext("Image category deleted"))
    |> redirect(to: helpers(conn).admin_portfolio_image_path(conn, :index))
  end
end
