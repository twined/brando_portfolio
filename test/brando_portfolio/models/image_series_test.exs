defmodule Brando.Portfolio.Integration.ImageSeriesTest do
  use ExUnit.Case
  use BrandoPortfolio.ConnCase

  alias BrandoPortfolio.Factory
  alias Brando.Portfolio.ImageSeries

  setup do
    user = Factory.insert(:user)
    category = Factory.insert(:image_category, creator: user)
    series = Factory.insert(:image_series, creator: user, image_category: category)
    {:ok, %{user: user, category: category, series: series}}
  end

  test "by_category_id", %{category: category} do
    result = Brando.repo.all(ImageSeries.by_category_id(category.id))
    assert length(result) == 1
    series = List.first(result)
    assert series.name == "Series name"
  end

  test "meta", %{series: series} do
    assert ImageSeries.__name__(:singular) == "imageserie"
    assert ImageSeries.__name__(:plural) == "imageseries"
    assert ImageSeries.__repr__(series) == "Series name – 0 image(s)."
  end
end
