defmodule Brando.Portfolio.ImageSeriesService do
  @moduledoc """
  Services for ImageSeries
  """

  alias Brando.Portfolio.ImageSeries
  import Ecto.Query

  @doc """
  Returns the model's slug
  """
  @spec get_slug_by(Keyword.t) :: ImageSeries.t | no_return
  def get_slug_by(id: id) do
    Brando.repo.one!(
      from m in ImageSeries,
        select: m.slug,
         where: m.id == ^id
    )
  end
end
