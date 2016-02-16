defmodule Brando.Portfolio.Admin.ImageSeriesView do
  @moduledoc """
  View for the Brando Images module.
  """
  use Brando.Web, :view
  use Brando.Sequence, :view

  import Brando.Portfolio.Gettext

  alias Brando.Portfolio.Admin.ImageSeriesForm
  alias Brando.Portfolio.Admin.ImageSeriesConfigForm

  def render("upload_post.json", %{image: image}) do
    %{status: "200", id: image.id}
  end
end
