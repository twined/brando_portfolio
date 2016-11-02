defmodule Brando.Portfolio.Admin.FrontpagePhotoForm do
  @moduledoc """
  A form for the FrontpagePhoto schema. See the `Brando.Form` module for more
  documentation
  """
  use Brando.Form

  form "frontpage_photo", [schema: Brando.Portfolio.FrontpagePhoto,
                           helper: :admin_portfolio_frontpage_photo_path,
                           class: "grid-form"] do
    field :photo, :file, [required: false]
    submit :save, [class: "btn btn-success"]
  end
end
