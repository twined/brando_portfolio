defmodule Brando.Portfolio.Routes.Admin do
  @moduledoc """
  Routes for Brando.Portfolio

  ## Usage:

  In `router.ex`

      scope "/admin", as: :admin do
        pipe_through :admin
        portfolio_routes "/images"

  """

  import Brando.Villain.Routes.Admin

  alias Brando.Portfolio.Admin.{
    ImageController, ImageSeriesController,
    ImageCategoryController,
    FrontpagePhotoController
  }

  defmacro portfolio_routes(path, opts \\ []), do:
    add_resources(path, opts)

  defp add_resources(path, _) do
    # options = Keyword.put([], :private, Macro.escape(%{}))

    quote do
      path = unquote(path)
      # opts = unquote(options)

      # series_opts = Keyword.put(opts, :as, "image_series")
      # categories_opts = Keyword.put(opts, :as, "image_category")

      scope path, as: :portfolio do
        get            "/",                            ImageController,          :index
        post           "/set-properties",              ImageController,          :set_properties
        post           "/delete-selected-images",      ImageController,          :delete_selected
        post           "/mark-as-cover",               ImageController,          :mark_as_cover

        villain_routes "/series",                      ImageSeriesController
        get            "/series",                      ImageSeriesController,    :index
        get            "/series/new/:id",              ImageSeriesController,    :new
        get            "/series/:id/edit",             ImageSeriesController,    :edit
        get            "/series/:id/recreate",         ImageSeriesController,    :recreate_sizes
        get            "/series/:id/configure",        ImageSeriesController,    :configure
        patch          "/series/:id/configure",        ImageSeriesController,    :configure_patch
        get            "/series/:id/delete",           ImageSeriesController,    :delete_confirm
        get            "/series/:id/upload",           ImageSeriesController,    :upload
        post           "/series/:id/upload",           ImageSeriesController,    :upload_post
        get            "/series/:filter/sort",         ImageSeriesController,    :sequence
        post           "/series/:filter/sort",         ImageSeriesController,    :sequence_post
        patch          "/series/:id",                  ImageSeriesController,    :update
        put            "/series/:id",                  ImageSeriesController,    :update
        delete         "/series/:id",                  ImageSeriesController,    :delete
        post           "/series",                      ImageSeriesController,    :create

        get            "/categories",                  ImageCategoryController,  :index
        get            "/categories/new",              ImageCategoryController,  :new
        get            "/categories/:filter/sort",     ImageCategoryController,  :sequence
        post           "/categories/:filter/sort",     ImageCategoryController,  :sequence_post
        get            "/categories/:id/orphans",      ImageCategoryController,  :handle_orphans
        post           "/categories/:id/orphans",      ImageCategoryController,  :handle_orphans_post
        get            "/categories/:id/edit",         ImageCategoryController,  :edit
        get            "/categories/:id/configure",    ImageCategoryController,  :configure
        patch          "/categories/:id/configure",    ImageCategoryController,  :configure_patch
        get            "/categories/:id/propagate",    ImageCategoryController,  :propagate_configuration
        get            "/categories/:id/delete",       ImageCategoryController,  :delete_confirm
        patch          "/categories/:id",              ImageCategoryController,  :update
        delete         "/categories/:id",              ImageCategoryController,  :delete
        post           "/categories",                  ImageCategoryController,  :create

        get            "/frontpage_photos",            FrontpagePhotoController, :index
        get            "/frontpage_photos/new",        FrontpagePhotoController, :new
        get            "/frontpage_photos/:id/edit",   FrontpagePhotoController, :edit
        get            "/frontpage_photos/:id/delete", FrontpagePhotoController, :delete_confirm
        get            "/frontpage_photos/:id",        FrontpagePhotoController, :show
        post           "/frontpage_photos",            FrontpagePhotoController, :create
        delete         "/frontpage_photos/:id",        FrontpagePhotoController, :delete
        patch          "/frontpage_photos/:id",        FrontpagePhotoController, :update
        put            "/frontpage_photos/:id",        FrontpagePhotoController, :update
      end
    end
  end
end
