defmodule Brando.Portfolio.Integration.ImageCategoryTest do
  use ExUnit.Case
  use BrandoPortfolio.ConnCase

  alias BrandoPortfolio.Factory
  alias Brando.Portfolio.ImageCategory
  alias Brando.Portfolio.ImageCategoryService

  setup do
    user = Factory.insert(:user)
    category = Factory.insert(:image_category, creator: user)
    series = Factory.insert(:image_series, creator: user, image_category: category)
    {:ok, %{user: user, category: category, series: series}}
  end

  test "get_slug", %{category: category} do
    assert ImageCategoryService.get_slug_by(id: category.id) == "test-category"
  end

  test "meta", %{category: category} do
    assert ImageCategory.__name__(:singular) == "image category"
    assert ImageCategory.__name__(:plural) == "image categories"
    assert ImageCategory.__repr__(category) == "Test Category"
  end
end
