defmodule Brando.Portfolio.Menu do
  @moduledoc """
  Menu definitions for the Portfolio Menu. See `Brando.Menu` docs for
  more information
  """
  use Brando.Menu
  import Brando.Portfolio.Gettext

  menu %{
    name: gettext("Portfolio"), anchor: "portfolio", icon: "fa fa-picture-o icon",
      submenu: [
        %{name: gettext("Index"), url: {:admin_portfolio_image_path, :index}},
        %{name: gettext("Frontpage index"), url: {:admin_portfolio_frontpage_photo_path, :index}}
      ]}
end
