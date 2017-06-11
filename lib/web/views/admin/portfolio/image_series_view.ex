defmodule Brando.Portfolio.Admin.ImageSeriesView do
  @moduledoc """
  View for the Brando Images module.
  """
  use Brando.Web, :view
  use Brando.Sequence, :view
  import Brando.Portfolio.Gettext
  alias Brando.Portfolio.Admin.ImageSeriesForm

  def render("upload_post.json", %{status: 200, image: img}) do
    %{status: "200", id: img.id}
  end

  def render("upload_post.json", %{status: 400, error_msg: error_msg}) do
    error_msg
  end
end