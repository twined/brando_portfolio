defmodule Brando.Portfolio.Integration.ImageTest do
  use ExUnit.Case
  use BrandoPortfolio.ConnCase

  alias BrandoPortfolio.Factory

  alias Brando.Portfolio.Image
  alias Brando.Portfolio.ImageSeries
  alias Brando.Portfolio.Utils

  setup do
    user = Factory.insert(:user)
    category = Factory.insert(:image_category, creator: user)
    series = Factory.insert(:image_series, creator: user, image_category: category)
    {:ok, %{user: user, category: category, series: series}}
  end

  test "create/2", %{user: user, series: series} do
    image = Factory.insert(:image, creator: user, image_series: series)

    assert image.creator_id == user.id
    assert image.image_series_id == series.id
  end

  test "update/2", %{user: user, series: series} do
    image = Factory.insert(:image, creator: user, image_series: series)

    assert image.creator_id == user.id
    assert image.image_series_id == series.id
    assert image.sequence == 0

    assert {:ok, image} = Image.update(image, %{"sequence" => 4})
    assert image.sequence == 4
  end

  test "update/2 bad params", %{user: user, series: series} do
    image = Factory.insert(:image, creator: user, image_series: series)

    assert image.creator_id == user.id
    assert image.image_series_id == series.id
    assert image.sequence == 0

    assert {:error, changeset} = Image.update(image, %{"sequence" => "string"})
    assert changeset.errors == [sequence: {"is invalid", [type: :integer, validation: :cast]}]
  end

  test "get/1", %{user: user, series: series} do
    image = Factory.insert(:image, creator: user, image_series: series)

    assert (Brando.repo.get_by!(Image, id: image.id)).id == image.id
    assert (Brando.repo.get_by!(Image, id: image.id)).creator_id == image.creator_id
    assert_raise Ecto.NoResultsError, fn ->
      Brando.repo.get_by!(Image, id: 1234)
    end
  end

  test "get!/1", %{user: user, series: series} do
    image = Factory.insert(:image, creator: user, image_series: series)
    assert (Brando.repo.get_by!(Image, id: image.id)).id
           == image.id
    assert_raise Ecto.NoResultsError, fn ->
       Brando.repo.get_by!(Image, id: 1234)
    end
  end

  test "sequence/2", %{user: user, series: series} do
    image1 = Factory.insert(:image, creator: user, image_series: series)
    image2 = Factory.insert(:image, creator: user, image_series: series, sequence: 1)

    assert image1.sequence == 0
    assert image2.sequence == 1

    assert {:ok, _} = Image.sequence([to_string(image1.id),
                                     to_string(image2.id)], [1, 0])

    image1 = Brando.repo.get_by!(Image, id: image1.id)
    image2 = Brando.repo.get_by!(Image, id: image2.id)
    assert image1.sequence == 1
    assert image2.sequence == 0
  end

  test "delete_images_for/1", %{user: user, series: series} do
    image = Factory.insert(:image, creator: user, image_series: series)
    assert Brando.repo.get_by!(Image, id: image.id).id == image.id

    image = Factory.insert(:image, creator: user, image_series: series)
    assert Brando.repo.get_by!(Image, id: image.id).id == image.id

    series =
      ImageSeries
      |> Ecto.Query.preload([:images])
      |> Brando.repo.get_by!(id: series.id)
      |> Brando.repo.preload(:images)

    assert Enum.count(series.images) == 2
    Utils.delete_images_for(:image_series, series.id)

    series =
      ImageSeries
      |> Ecto.Query.preload([:images])
      |> Brando.repo.get_by!(id: series.id)
      |> Brando.repo.preload(:images)

    assert Enum.count(series.images) == 0
  end

  test "meta", %{user: user, series: series} do
    image = Factory.insert(:image, creator: user, image_series: series)

    assert Brando.Image.__name__(:singular) == "image"
    assert Brando.Image.__name__(:plural) == "images"
    assert Brando.Image.__repr__(image) == "#{image.id} | /tmp/path/to/fake/image.jpg"
  end
end
