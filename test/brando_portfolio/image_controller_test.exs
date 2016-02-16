defmodule Brando.Portfolio.Image.ControllerTest do
  use ExUnit.Case
  use BrandoPortfolio.ConnCase
  use Plug.Test
  use RouterHelper

  alias BrandoPortfolio.Factory

  alias Brando.Portfolio.Image

  @image_url "/admin/portfolio"

  @path "#{Path.expand("../", __DIR__)}/fixtures/sample0.png"

  @up_params %Plug.Upload{content_type: "image/png",
                          filename: "sample0.png", path: @path}

  setup do
    user = Factory.create(:user)
    category = Factory.create(:image_category, creator: user)
    series = Factory.create(:image_series, creator: user, image_category: category)
    {:ok, %{user: user, category: category, series: series}}
  end

  test "index" do
    conn =
      :get
      |> call("#{@image_url}/")
      |> with_user
      |> send_request

    assert html_response(conn, 200) =~ "Index"
    assert html_response(conn, 200) =~ "Test category"
    assert html_response(conn, 200) =~ "Series name"
  end

  test "set_properties", %{user: user, series: series} do
    # upload first

    conn =
      :post
      |> call("#{@image_url}/series/#{series.id}/upload", %{"id" => series.id, "image" => @up_params})
      |> with_user(user)
      |> as_json
      |> send_request

    assert conn.status == 200
    response = json_response(conn, 200)
    assert Map.get(response, "status") == "200"

    image = Brando.repo.all(
      from m in Image,
        where: m.image_series_id == ^series.id,
        order_by: m.sequence
    ) |> List.first

    refute image.image.credits
    refute image.image.title

    conn =
      :post
      |> call("#{@image_url}/set-properties", %{"id" => image.id, "form" => %{"credits" => "credits", "title" => "title"}})
      |> with_user(user)
      |> as_json
      |> send_request

    response = json_response(conn, 200)

    assert Map.get(response, "attrs") == %{"credits" => "credits", "title" => "title"}
    assert Map.get(response, "status") == "200"

    image = Brando.repo.all(
      from m in Image,
        where: m.image_series_id == ^series.id,
        order_by: m.sequence
    ) |> List.first

    assert image.image.credits == "credits"
    assert image.image.title   == "title"
  end

  test "delete_selected", %{user: user, series: series} do
    # upload first

    conn =
      :post
      |> call("#{@image_url}/series/#{series.id}/upload", %{"id" => series.id, "image" => @up_params})
      |> with_user(user)
      |> as_json
      |> send_request

    assert conn.status == 200
    response = json_response(conn, 200)
    assert Map.get(response, "status") == "200"

    images = Brando.repo.all(
      from m in Image,
        select: m.id,
        where: m.image_series_id == ^series.id,
        order_by: m.sequence
    )

    conn =
      :post
      |> call("#{@image_url}/delete-selected-images", %{"ids" => images})
      |> with_user(user)
      |> as_json
      |> send_request

    assert json_response(conn, 200) == %{"status" => "200", "ids" => images}

    images = Brando.repo.all(
      from m in Image,
        select: m.id,
        where: m.image_series_id == ^series.id,
        order_by: m.sequence
    )

    assert images == []
  end
end
