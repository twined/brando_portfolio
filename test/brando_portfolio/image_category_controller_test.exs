defmodule Brando.Portfolio.ImageCategory.ControllerTest do
  use ExUnit.Case
  use BrandoPortfolio.ConnCase
  use Plug.Test
  use RouterHelper

  alias BrandoPortfolio.Factory

  @images_url "/admin/portfolio"

  test "new" do
    conn =
      :get
      |> call("#{@images_url}/categories/new")
      |> with_user
      |> send_request

    assert html_response(conn, 200) =~ "New image category"
  end

  test "edit" do
    user = Factory.create(:user)
    category = Factory.create(:image_category, creator: user)

    conn =
      :get
      |> call("#{@images_url}/categories/#{category.id}/edit")
      |> with_user
      |> send_request

    assert html_response(conn, 200) =~ "Edit image category"

    assert_raise Plug.Conn.WrapperError, fn ->
      :get
      |> call("#{@images_url}/categories/1234/edit")
      |> with_user
      |> send_request
    end
  end

  test "create (post) w/params" do
    user = Factory.create(:user)
    category_params = Factory.build(:image_category_params)

    conn =
      :post
      |> call("#{@images_url}/categories/", %{"imagecategory" => category_params})
      |> with_user(user)
      |> send_request

    assert redirected_to(conn, 302) =~ "#{@images_url}"
    assert get_flash(conn, :notice) == "Image category created"
  end

  test "create (post) w/erroneus params" do
    user = Factory.create(:user)

    broken_category_params =
      :image_category_params
      |> Factory.build(creator: user)
      |> Map.delete("name")
      |> Map.delete("slug")

    conn =
      :post
      |> call("#{@images_url}/categories/", %{"imagecategory" => broken_category_params})
      |> with_user(user)
      |> send_request

    assert html_response(conn, 200) =~ "New image category"
    assert get_flash(conn, :error) == "Errors in form"
  end

  test "update (post) w/params" do
    user = Factory.create(:user)
    category = Factory.create(:image_category, creator: user)

    category_params = Factory.build(:image_category_params, creator: user, name: "New name")

    conn =
      :patch
      |> call("#{@images_url}/categories/#{category.id}", %{"imagecategory" => category_params})
      |> with_user
      |> send_request

    assert redirected_to(conn, 302) =~ "#{@images_url}"
    assert get_flash(conn, :notice) == "Image category updated"
  end

  test "config (get)" do
    user = Factory.create(:user)
    category = Factory.create(:image_category, creator: user)

    conn =
      :get
      |> call("#{@images_url}/categories/#{category.id}/configure")
      |> with_user
      |> send_request

    assert html_response(conn, 200) =~ "Configure image category"
    assert html_response(conn, 200) =~ "imagecategoryconfig[cfg]"

    assert_raise Plug.Conn.WrapperError, fn ->
      :get
      |> call("#{@images_url}/categories/1234/configure")
      |> with_user
      |> send_request
    end
  end

  test "config (post) w/params" do
    user = Factory.create(:user)
    category = Factory.create(:image_category, creator: user)
    category_params = Factory.build(:image_category_params, creator: user)

    conn =
      :patch
      |> call("#{@images_url}/categories/#{category.id}/configure", %{"imagecategoryconfig" => category_params})
      |> with_user
      |> send_request

    assert redirected_to(conn, 302) =~ "#{@images_url}"
    assert get_flash(conn, :notice) == "Image category configured"
  end

  test "delete_confirm" do
    user = Factory.create(:user)
    category = Factory.create(:image_category, creator: user)

    conn =
      :get
      |> call("#{@images_url}/categories/#{category.id}/delete")
      |> with_user
      |> send_request

    assert html_response(conn, 200) =~ "Delete image category: Test Category"
  end

  test "delete" do
    user = Factory.create(:user)
    category = Factory.create(:image_category, creator: user)

    conn =
      :delete
      |> call("#{@images_url}/categories/#{category.id}")
      |> with_user
      |> send_request

    assert redirected_to(conn, 302) =~ "#{@images_url}"
    assert get_flash(conn, :notice) == "Image category deleted"
  end
end
