defmodule Brando.Portfolio.FrontpagePhoto.ControllerTest do
  use ExUnit.Case
  use BrandoPortfolio.ConnCase
  use Plug.Test
  use RouterHelper

  alias BrandoPortfolio.Factory

  @portfolio_url "/admin/portfolio"
  @fp_url "/admin/portfolio/frontpage_photos"

  @path1 "#{Path.expand("../", __DIR__)}/fixtures/sample0.png"
  @path2 "#{Path.expand("../", __DIR__)}/fixtures/sample1.png"

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
    {:ok, %{user: user}}
  end

  test "index" do
    conn =
      :get
      |> call("#{@fp_url}")
      |> with_user
      |> send_request

    assert html_response(conn, 200) =~ "Index - frontpage photos"
  end

  test "new" do
    conn =
      :get
      |> call("#{@fp_url}/new")
      |> with_user
      |> send_request

    assert html_response(conn, 200) =~ "New frontpage photo"
  end

  test "show", %{user: user} do
    fp_photo = Factory.insert(:frontpage_photo)

    conn =
      :get
      |> call("#{@fp_url}/#{fp_photo.id}")
      |> with_user(user)
      |> send_request

    assert html_response(conn, 200) =~ "Show frontpage photo"
  end

  test "edit" do
    fp_photo = Factory.insert(:frontpage_photo)

    conn =
      :get
      |> call("#{@fp_url}/#{fp_photo.id}/edit")
      |> with_user
      |> send_request

    assert html_response(conn, 200) =~ "Edit frontpage photo"

    assert_raise Plug.Conn.WrapperError, fn ->
      :get
      |> call("#{@fp_url}/123456/edit")
      |> with_user
      |> send_request
    end
  end

  test "create (post) w/params", %{user: user} do
    fp_photo_params = %{"photo" => @up_params}

    conn =
      :post
      |> call("#{@fp_url}/", %{"frontpage_photo" => fp_photo_params})
      |> with_user(user)
      |> send_request

    assert redirected_to(conn, 302) =~ @portfolio_url
  end

  test "create (post) w/broken params", %{user: user} do
    fp_photo_params = %{"photo" => nil}

    conn =
      :post
      |> call("#{@fp_url}/", %{"frontpage_photo" => fp_photo_params})
      |> with_user(user)
      |> send_request

    assert html_response(conn, 200) =~ "New frontpage photo"
    assert get_flash(conn, :error) == "Errors in form"
  end

  test "update (post) w/params", %{user: user} do
    fp_photo = Factory.insert(:frontpage_photo)
    fp_photo_params = %{"photo" => @up_params2}

    conn =
      :patch
      |> call("#{@fp_url}/#{fp_photo.id}", %{"frontpage_photo" => fp_photo_params})
      |> with_user(user)
      |> send_request

    assert redirected_to(conn, 302) =~ @portfolio_url
    assert get_flash(conn, :info) == "Frontpage photo updated"
  end

  test "update (post) w/broken params", %{user: user} do
    fp_photo = Factory.insert(:frontpage_photo)
    fp_photo_params = %{"photo" => nil}

    conn =
      :patch
      |> call("#{@fp_url}/#{fp_photo.id}", %{"frontpage_photo" => fp_photo_params})
      |> with_user(user)
      |> send_request

    assert html_response(conn, 200) =~ "Edit frontpage photo"
    assert get_flash(conn, :error) == "Errors in form"
  end

  test "delete_confirm" do
    fp_photo = Factory.insert(:frontpage_photo)

    conn =
      :get
      |> call("#{@fp_url}/#{fp_photo.id}/delete")
      |> with_user
      |> send_request

    assert html_response(conn, 200) =~ "Delete frontpage photo"
  end

  test "delete" do
    fp_photo = Factory.insert(:frontpage_photo)

    conn =
      :delete
      |> call("#{@fp_url}/#{fp_photo.id}")
      |> with_user
      |> send_request

    assert redirected_to(conn, 302) =~ @portfolio_url
    assert get_flash(conn, :info) == "Frontpage photo deleted"
  end
end
