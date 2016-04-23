defmodule Brando.Portfolio.Admin.ImageCategoryView do
  @moduledoc """
  View for the Brando Images module.
  """
  use Brando.Web, :view
  use Brando.Sequence, :view

  import Brando.Portfolio.Gettext

  alias Brando.Portfolio.Admin.ImageCategoryForm

  def render("propagate_configuration.json", _) do
    %{status: 200}
  end
end
