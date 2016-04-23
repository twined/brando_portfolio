defmodule Brando.Portfolio.Admin.ImageCategoryView do
  @moduledoc """
  View for the Brando Images module.
  """
  use Brando.Web, :view
  use Brando.Sequence, :view

  import Brando.Portfolio.Gettext

  alias Brando.Portfolio.Admin.ImageCategoryForm

  def render("propagate_configuration.json", %{orphaned_series: orphaned_series, id: id, conn: conn}) do
    return = %{status: 200}

    if orphaned_series != [] do
      Map.put(:orphaned_series, helpers(conn).admin_portfolio_image_category_path(conn, :handle_orphans, id))
    else
      return
    end
  end
end
