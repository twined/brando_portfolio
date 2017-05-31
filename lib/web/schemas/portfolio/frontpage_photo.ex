defmodule Brando.Portfolio.FrontpagePhoto do
  use Brando.Web, :schema
  use Brando.Field.ImageField

  import Brando.Portfolio.Gettext

  schema "portfolio_frontpage_photos" do
    field :photo, Brando.Type.Image
    timestamps()
  end

  has_image_field :photo, %{
    allowed_mimetypes: ["image/jpeg", "image/png", "image/gif"],
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

  @required_fields ~w(photo)a
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `schema` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_upload({:image, :photo})
    |> cleanup_old_images()
  end

  #
  # Meta

  use Brando.Meta.Schema, [
    singular: "frontpage photo",
    plural: "frontpage photos",
    repr: &("#{&1.id} | #{&1.photo.path}"),
    fields: [
      id: gettext("Id"),
      photo: gettext("Photo"),
      inserted_at: gettext("Inserted at"),
      updated_at: gettext("Updated at")],
    hidden_fields: []
  ]
end
