defmodule Brando.Portfolio.Admin.ImageSeriesConfigForm do
  @moduledoc """
  A form for the ImageSeries configuration model. See the `Brando.Form`
  module for more documentation
  """

  use Brando.Form
  alias Brando.Portfolio.ImageSeries

  form "imageseriesconfig", [schema: ImageSeries,
                             helper: :admin_portfolio_image_series_path,
                             class: "grid-form"] do
    field :cfg, :textarea
    submit :save, [class: "btn btn-success"]
  end
end
