defmodule Brando.Portfolio.Admin.FrontpagePhotoController do
  use Brando.Web, :controller

  import Brando.Portfolio.Gettext
  import Brando.Utils, only: [helpers: 1]
  import Brando.Images.Utils

  alias Brando.Portfolio.FrontpagePhoto

  plug :scrub_params, "frontpage_photo" when action in [:create, :update]

  def index(conn, _params) do
    frontpage_photos = Brando.repo.all(FrontpagePhoto)

    conn
    |> assign(:page_title, gettext("Index - frontpage photos"))
    |> render("index.html", frontpage_photos: frontpage_photos)
  end

  def new(conn, _params) do
    changeset = FrontpagePhoto.changeset(%FrontpagePhoto{})

    render conn, "new.html", [
      changeset: changeset,
      page_title: gettext("New frontpage photo")
    ]
  end

  def create(conn, %{"frontpage_photo" => params}) do
    cs = FrontpagePhoto.changeset(%FrontpagePhoto{}, params)

    case Brando.repo.insert(cs) do
      {:ok, _} ->
        conn
        |> put_flash(:info, gettext("Frontpage photo created"))
        |> redirect(to: helpers(conn).admin_portfolio_frontpage_photo_path(conn, :index))
      {:error, cs} ->
        conn = put_flash(conn, :error, gettext("Errors in form"))
        render conn, "new.html", [
          changeset:  cs,
          page_title: gettext("New frontpage photo")
        ]
    end
  end

  def show(conn, %{"id" => id}) do
    frontpage_photo = Brando.repo.get!(FrontpagePhoto, id)

    render conn, "show.html", [
      frontpage_photo: frontpage_photo,
      page_title:      gettext("Show frontpage photo")
    ]
  end

  def edit(conn, %{"id" => id}) do
    fphoto = Brando.repo.get!(FrontpagePhoto, id)
    cs     = FrontpagePhoto.changeset(fphoto)

    render conn, "edit.html", [
      changeset:       cs,
      frontpage_photo: fphoto,
      page_title:      gettext("Edit frontpage photo")
    ]
  end

  def update(conn, %{"id" => id, "frontpage_photo" => params}) do
    fphoto = Brando.repo.get!(FrontpagePhoto, id)
    changeset = FrontpagePhoto.changeset(fphoto, params)

    case Brando.repo.update(changeset) do
      {:ok, _} ->
        conn
        |> put_flash(:info, gettext("Frontpage photo updated"))
        |> redirect(to: helpers(conn).admin_portfolio_frontpage_photo_path(conn, :index))
      {:error, changeset} ->
        conn = put_flash(conn, :error, gettext("Errors in form"))

        render conn, "edit.html", [
          frontpage_photo: fphoto,
          changeset:       changeset,
          page_title:      gettext("Edit frontpage photo"),
        ]
    end
  end

  def delete_confirm(conn, %{"id" => id}) do
    record = Brando.repo.get!(FrontpagePhoto, id)

    render conn, :delete_confirm, [
      record:     record,
      page_title: gettext("Confirm deletion")
    ]
  end

  def delete(conn, %{"id" => id}) do
    frontpage_photo = Brando.repo.get!(FrontpagePhoto, id)

    delete_original_and_sized_images(frontpage_photo, :photo)
    Brando.repo.delete!(frontpage_photo)

    conn
    |> put_flash(:info, gettext("Frontpage photo deleted"))
    |> redirect(to: helpers(conn).admin_portfolio_frontpage_photo_path(conn, :index))
  end
end
