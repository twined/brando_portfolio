defmodule Brando.Portfolio.Admin.FrontpagePhotoController do
  use Brando.Web, :controller

  import Brando.Plug.Uploads
  import Brando.Portfolio.Gettext
  import Brando.Utils, only: [helpers: 1]

  alias Brando.Portfolio.FrontpagePhoto

  plug :scrub_params, "frontpage_photo" when action in [:create, :update]
  plug :check_for_uploads, {"frontpage_photo", FrontpagePhoto} when action in [:create, :update]

  def index(conn, _params) do
    frontpage_photos = Repo.all(FrontpagePhoto)

    conn
    |> assign(:page_title, gettext("Index - frontpage photos"))
    |> render("index.html", frontpage_photos: frontpage_photos)
  end

  def new(conn, _params) do
    changeset = FrontpagePhoto.changeset(%FrontpagePhoto{})

    conn
    |> assign(:page_title, gettext("New frontpage photo"))
    |> render("new.html", changeset: changeset)
  end

  def create(conn, %{"frontpage photo" => frontpage_photo_params}) do
    changeset = FrontpagePhoto.changeset(%FrontpagePhoto{}, frontpage_photo_params)

    case Repo.insert(changeset) do
      {:ok, _} ->
        conn
        |> put_flash(:info, gettext("frontpage photo created"))
        |> redirect(to: helpers(conn).admin_portfolio_frontpage_photo_path(conn, :index))
      {:error, changeset} ->
        conn
        |> put_flash(:error, gettext("Errors in form"))
        |> assign(:page_title, gettext("New frontpage photo"))
        |> render("new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    frontpage_photo = Repo.get!(FrontpagePhoto, id)
    conn
    |> assign(:page_title, gettext("Show frontpage photo"))
    |> render("show.html", frontpage_photo: frontpage_photo)
  end

  def edit(conn, %{"id" => id}) do
    frontpage_photo = Repo.get!(FrontpagePhoto, id)
    changeset = FrontpagePhoto.changeset(frontpage_photo)

    conn
    |> assign(:page_title, gettext("Edit frontpage photo"))
    |> render("edit.html", frontpage_photo: frontpage_photo,
                           changeset: changeset)
  end

  def update(conn, %{"id" => id, "frontpage_photo" => frontpage_photo_params}) do
    frontpage_photo = Repo.get!(FrontpagePhoto, id)
    changeset = FrontpagePhoto.changeset(frontpage_photo, frontpage_photo_params)

    case Repo.update(changeset) do
      {:ok, _} ->
        conn
        |> put_flash(:info, gettext("frontpage photo updated"))
        |> redirect(to: helpers(conn).admin_portfolio_frontpage_photo_path(conn, :index))
      {:error, changeset} ->
        conn
        |> put_flash(:error, gettext("Errors in form"))
        |> assign(:page_title, gettext("Edit frontpage photo"))
        |> render("edit.html", frontpage_photo: frontpage_photo,
                               changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    frontpage_photo = Repo.get!(FrontpagePhoto, id)
    FrontpagePhoto.delete(frontpage_photo)

    conn
    |> put_flash(:info, gettext("frontpage photo deleted"))
    |> redirect(to: helpers(conn).admin_portfolio_frontpage_photo_path(conn, :index))
  end

  def delete_confirm(conn, %{"id" => id}) do
    record = Repo.get!(FrontpagePhoto, id)
    conn
    |> assign(:record, record)
    |> assign(:page_title, gettext("Confirm deletion"))
    |> render(:delete_confirm)
  end
end
