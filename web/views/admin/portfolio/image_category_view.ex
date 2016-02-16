defmodule Brando.Portfolio.Admin.ImageCategoryView do
  @moduledoc """
  View for the Brando Images module.
  """
  use Brando.Web, :view
  use Brando.Sequence, :view

  import Brando.Portfolio.Gettext

  alias Brando.Portfolio.Admin.ImageCategoryForm
  alias Brando.Portfolio.Admin.ImageCategoryConfigForm
end
