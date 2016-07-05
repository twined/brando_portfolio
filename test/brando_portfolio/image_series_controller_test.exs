defmodule Brando.Portfolio.ImageSeries.ControllerTest do
  use ExUnit.Case
  use BrandoPortfolio.ConnCase
  use Plug.Test
  use RouterHelper

  alias BrandoPortfolio.Factory

  alias Brando.Portfolio.Image
  alias Brando.Type.ImageConfig

  @portfolio_url "/admin/portfolio"
  @series_url "/admin/portfolio/series"

  @path1 "#{Path.expand("../", __DIR__)}/fixtures/sample0.png"
  @path2 "#{Path.expand("../", __DIR__)}/fixtures/sample1.png"

  @cfg Map.from_struct(%ImageConfig{})
  @cfg_changed Map.put(@cfg, :random_filename, true)

  @up_params %Plug.Upload{
    content_type: "image/png",
    filename: "sample0.png", path: @path1
  }

  @up_params2 %Plug.Upload{
    content_type: "image/png",
    filename: "sample1.png", path: @path2
  }

  setup do
    user = Factory.insert(:user)
    category = Factory.insert(:image_category, creator: user)
    series = Factory.insert(:image_series, creator: user, image_category: category)
    {:ok, %{user: user, category: category, series: series}}
  end

  test "new", %{category: category} do
    conn =
      :get
      |> call("#{@series_url}/new/#{category.id}")
      |> with_user
      |> send_request

    assert html_response(conn, 200) =~ "New image series"
  end

  test "edit", %{series: series} do
    conn =
      :get
      |> call("#{@series_url}/#{series.id}/edit")
      |> with_user
      |> send_request

    assert html_response(conn, 200) =~ "Edit image series"

    assert_raise Plug.Conn.WrapperError, fn ->
      :get
      |> call("#{@series_url}/1234/edit")
      |> with_user
      |> send_request
    end
  end

  test "create (post) w/params", %{user: user, category: category} do
    series_params = Factory.params_for(:image_series, %{creator_id: user.id,
                                                        image_category_id: category.id})

    conn =
      :post
      |> call("#{@series_url}/", %{"imageseries" => series_params})
      |> with_user(user)
      |> send_request

    assert redirected_to(conn, 302) =~ @portfolio_url
    assert get_flash(conn, :notice) == "Image series created"
  end

  test "update (post) w/params", %{user: user, series: series, category: category} do
    series_params = Factory.params_for(:image_series, %{creator_id: user.id,
                                                        image_category_id: category.id,
                                                        name: "New name"})

    conn =
      :patch
      |> call("#{@series_url}/#{series.id}", %{"imageseries" => series_params})
      |> with_user
      |> send_request

    assert redirected_to(conn, 302) =~ @portfolio_url
    assert get_flash(conn, :notice) == "Image series updated"
  end

  test "delete_confirm", %{series: series} do
    conn =
      :get
      |> call("#{@series_url}/#{series.id}/delete")
      |> with_user
      |> send_request

    assert html_response(conn, 200) =~ "Delete image series: Series name"
  end

  test "delete", %{series: series} do
    conn =
      :delete
      |> call("#{@series_url}/#{series.id}")
      |> with_user
      |> send_request

    assert redirected_to(conn, 302) =~ @portfolio_url
    assert get_flash(conn, :notice) == "Image series deleted"
  end

  test "upload", %{series: series} do
    conn =
      :get
      |> call("#{@series_url}/#{series.id}/upload")
      |> with_user
      |> send_request

    assert html_response(conn, 200)
           =~ "Upload to this image series &raquo; <strong>Series name</strong>"
  end

  test "upload_post", %{user: user, series: series} do
    conn =
      :post
      |> call("#{@series_url}/#{series.id}/upload", %{"id" => series.id, "image" => @up_params})
      |> with_user(user)
      |> as_json
      |> send_request

    assert conn.status == 200
    response = json_response(conn, 200)
    assert Map.get(response, "status") == "200"
  end

  test "sort", %{user: user, series: series} do
    File.rm_rf!(Brando.config(:media_path))
    File.mkdir_p!(Brando.config(:media_path))

    conn =
      :post
      |> call("#{@series_url}/#{series.id}/upload", %{"id" => series.id, "image" => @up_params})
      |> with_user(user)
      |> as_json
      |> send_request

    assert conn.status == 200
    response = json_response(conn, 200)
    assert Map.get(response, "status") == "200"
    id1 = Map.get(response, "id")

    conn =
      :post
      |> call("#{@series_url}/#{series.id}/upload", %{"id" => series.id, "image" => @up_params2})
      |> with_user(user)
      |> as_json
      |> send_request

    assert conn.status == 200
    response = json_response(conn, 200)
    assert Map.get(response, "status") == "200"
    id2 = Map.get(response, "id")

    conn =
      :get
      |> call("#{@series_url}/#{series.id}/sort")
      |> with_user
      |> send_request

    assert conn.status == 200
    assert html_response(conn, 200)
           =~ "<img src=\"/media/portfolio/test-category/test-series/thumb/sample0-optimized.png\" />"

    conn =
      :post
      |> call("#{@series_url}/#{series.id}/sort", %{"order" => [to_string(id2), to_string(id1)]})
      |> with_user(user)
      |> as_json
      |> send_request

    assert conn.status == 200
    assert conn.path_info == ["admin", "portfolio", "series", "#{series.id}", "sort"]
    assert json_response(conn, 200) == %{"status" => "200"}

    img1 = Brando.repo.get_by!(Image, id: id1)
    img2 = Brando.repo.get_by!(Image, id: id2)

    assert img2.sequence < img1.sequence
  end

  test "configure get", %{series: series} do
    conn =
      :get
      |> call("#{@series_url}/#{series.id}/configure")
      |> with_user
      |> send_request

    assert html_response(conn, 200) =~ "Configure image series"
  end

  # test "configure patch", %{series: series} do
  #   conn =
  #     :patch
  #     |> call("#{@series_url}/#{series.id}/configure", %{"id" => series.id, "imageseriesconfig" => @cfg_changed})
  #     |> with_user
  #     |> send_request
  #
  #   assert redirected_to(conn, 302) =~ @portfolio_url
  #   assert get_flash(conn, :notice) == "Image series configured"
  # end
end
