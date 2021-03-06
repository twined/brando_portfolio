defmodule Brando.Portfolio.Admin.ImageView do
  @moduledoc """
  View for the Brando Images module.
  """
  use Brando.Web, :view

  import Brando.Portfolio.Gettext

  def render("delete_selected.json", assigns) do
    %{status: "200", ids: assigns[:ids]}
  end

  def render("mark_as_cover.json", assigns) do
    %{status: "200", ids: assigns[:ids], action: assigns[:action]}
  end

  def render("set_properties.json", assigns) do
    %{status: "200", id: assigns[:id], attrs: assigns[:attrs]}
  end
end
