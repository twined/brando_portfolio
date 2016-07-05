defmodule BrandoPortfolio.Factory do
  use ExMachina.Ecto, repo: Brando.repo

  alias Brando.Type.ImageConfig
  alias Brando.User
  alias Brando.Portfolio.{Image, ImageCategory, ImageSeries, FrontpagePhoto}

  @sizes %{
    "small" =>  %{"size" => "300", "quality" => 100},
    "thumb" =>  %{"size" => "150x150", "quality" => 100, "crop" => true}
  }

  def user_factory do
    %User{
      full_name: "James Williamson",
      email: "james@thestooges.com",
      password: "$2b$12$VD9opg289oNQAHii8VVpoOIOe.y4kx7.lGb9SYRwscByP.tRtJTsa",
      username: "jamesw",
      avatar: nil,
      role: [:admin, :superuser],
      language: "en"
    }
  end

  def image_series_factory do
    %ImageSeries{
      name: "Series name",
      slug: "series-name",
      data: ~s([{"type":"text","data":{"text":"About the series","type":"paragraph"}}]),
      html: "<p>About the series</p>",
      cfg: %ImageConfig{sizes: @sizes, upload_path: "portfolio/test-category/test-series"},
      sequence: 0,
      image_category: build(:image_category),
      creator: build(:user),
    }
  end

  def image_category_factory do
    %ImageCategory{
      cfg: %ImageConfig{sizes: @sizes, upload_path: "portfolio/test-category"},
      name: "Test Category",
      slug: "test-category",
      creator: build(:user)
    }
  end


  def image_factory do
    %Image{
      sequence: 0,
      image: %{
        title: "Title",
        credits: "credits",
        path: "/tmp/path/to/fake/image.jpg",
        sizes: %{
          small: "/tmp/path/to/fake/image.jpg",
          thumb: "/tmp/path/to/fake/thumb.jpg"
        }
      },
    }
  end

  def frontpage_photo_factory do
    %FrontpagePhoto{
      photo: %{
        title: "Title",
        credits: "credits",
        path: "/tmp/path/to/fake/image.jpg",
        sizes: %{
          small: "/tmp/path/to/fake/image.jpg",
          thumb: "/tmp/path/to/fake/thumb.jpg"
        }
      }
    }
  end
end
