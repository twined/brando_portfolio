defmodule Brando.Portfolio.ImageCategoryService do
  @moduledoc """
  Services for ImageCategory
  """
  alias Brando.Portfolio.ImageCategory
  import Ecto.Query

  @doc """
  Returns the model's slug
  """
  def get_slug_by(id: id) do
    Brando.repo.one!(
      from m in ImageCategory,
        select: m.slug,
         where: m.id == ^id
    )
  end
end
