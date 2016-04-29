defmodule Brando.Portfolio.FrontpagePhoto do
  use Brando.Web, :model
  use Brando.Field.ImageField

  import Brando.Gettext

  schema "portfolio_frontpage_photos" do
    field :photo, Brando.Type.Image
    timestamps
  end

  has_image_field :photo,
    %{allowed_mimetypes: ["image/jpeg", "image/png"],
      default_size: :medium,
      upload_path: Path.join(["images", "frontpage-photos"]),
      random_filename: true,
      size_limit: 10240000,
      sizes: %{
        "micro"  => %{"size" => "25x25>", "quality" => 100, "crop" => true},
        "thumb"  => %{"size" => "150x150>", "quality" => 100, "crop" => true},
        "small"  => %{"size" => "300", "quality" => 100},
        "medium" => %{"size" => "500", "quality" => 100},
        "large"  => %{"size" => "x600", "quality" => 100},
        "xlarge" => %{"size" => "900", "quality" => 100}
      }
    }

  @required_fields ~w(photo)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> cleanup_old_images()
  end

  #
  # Meta

  use Brando.Meta.Model, [
    singular: "frontpage photo",
    plural: "frontpage photos",
    repr: fn(_) -> "test" end,
    fields: [
      id: gettext("Id"),
      photo: gettext("Photo"),
      inserted_at: gettext("Inserted at"),
      updated_at: gettext("Updated at")],
    hidden_fields: []
  ]
end
