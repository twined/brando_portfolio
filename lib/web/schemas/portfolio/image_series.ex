defmodule Brando.Portfolio.ImageSeries do
  @moduledoc """
  Ecto schema for the Image Series schema
  and helper functions for dealing with the schema.
  """

  @type t :: %__MODULE__{}

  use Brando.Web, :schema
  use Brando.Sequence, :schema
  use Brando.Villain, :schema

  alias Brando.User
  alias Brando.Portfolio.Image
  alias Brando.Portfolio.ImageCategory

  import Brando.Portfolio.Gettext
  import Ecto.Query, only: [from: 2]

  @required_fields ~w(name slug image_category_id creator_id)a
  @optional_fields ~w(sequence cfg data html)a

  schema "portfolio_imageseries" do
    field :name, :string
    field :slug, :string
    villain()
    field :cfg, Brando.Type.ImageConfig
    belongs_to :creator, User
    belongs_to :image_category, ImageCategory
    has_many :images, Image
    sequenced()
    timestamps()
  end

  @doc """
  Casts and validates `params` against `schema` to create a valid
  changeset when action is :create.

  ## Example

      schema_changeset = changeset(%__MODULE__{}, :create, params)

  """
  @spec changeset(t, atom, Keyword.t | Options.t) :: t
  def changeset(schema, action, params \\ %{})
  def changeset(schema, :create, params) do
    schema
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:slug)
    |> Brando.Utils.Schema.avoid_slug_collision
    |> generate_html
    |> inherit_configuration
  end

  @doc """
  Casts and validates `params` against `schema` to create a valid
  changeset when action is :update.

  ## Example

      schema_changeset = changeset(%__MODULE__{}, :update, params)

  """
  @spec changeset(t, atom, Keyword.t | Options.t) :: t
  def changeset(schema, :update, params) do
    schema
    |> cast(params, @required_fields ++ @optional_fields)
    |> unique_constraint(:slug)
    |> Brando.Utils.Schema.avoid_slug_collision
    |> validate_paths
    |> generate_html
  end

  @doc """
  Get all imageseries in category `id`.
  """
  def by_category_id(id) do
    from m in __MODULE__,
         where: m.image_category_id == ^id,
      order_by: m.sequence,
       preload: [:images]
  end

  @doc """
  Before inserting changeset. Copies the series' category config.
  """
  def inherit_configuration(cs) do
    cat_id   = Ecto.Changeset.get_field(cs, :image_category_id)
    slug     = Ecto.Changeset.get_field(cs, :slug)
    category = Brando.repo.get(ImageCategory, cat_id)

    cfg =
      if slug do
        Map.put(category.cfg, :upload_path, Path.join(Map.get(category.cfg, :upload_path), slug))
      else
        category.cfg
      end

    put_change(cs, :cfg, cfg)
  end

  @doc """
  Checks if slug or category was changed in changeset.

  If it is, move and fix paths/files + redo thumbs
  """
  def validate_paths(cs) do
    new_category_id = get_change(cs, :image_category_id)
    cs =
      if new_category_id do
        # build new upload_path
        cfg          = cs.data.cfg
        new_category = Brando.repo.get(ImageCategory, new_category_id)
        new_path     = Path.join(new_category.cfg.upload_path, cs.data.slug)
        cfg          = Map.put(cfg, :upload_path, new_path)

        put_change(cs, :cfg, cfg)
      else
        cs
      end

    slug = get_change(cs, :slug)
    if slug do
      cfg        = get_change(cs, :cfg) || cs.data.cfg
      split_path = Path.split(cfg.upload_path)

      new_path =
        split_path
        |> List.delete_at(Enum.count(split_path) - 1)
        |> Path.join
        |> Path.join(slug)

      cfg = Map.put(cfg, :upload_path, new_path)

      put_change(cs, :cfg, cfg)
    else
      cs
    end
  end

  #
  # Meta

  use Brando.Meta.Schema, [
    singular: gettext("imageserie"),
    plural: gettext("imageseries"),
    repr: fn (schema) ->
       schema = Brando.repo.preload(schema, :images)
       image_count = Enum.count(schema.images)
       "#{schema.name} – #{image_count} #{gettext("image(s)")}."
    end,
    fields: [
      id: gettext("ID"),
      name: gettext("Name"),
      slug: gettext("Slug"),
      cfg: gettext("Configuration"),
      html: gettext("HTML"),
      data: gettext("Data"),
      sequence: gettext("Sequence"),
      creator: gettext("Creator"),
      images: gettext("Images"),
      image_category: gettext("Image category"),
      image_category_id: gettext("Image category"),
      inserted_at: gettext("Inserted at"),
      updated_at: gettext("Updated at")
    ],
    help: [
      data: gettext("This is for information about the image series, not for uploading images.")
    ],
    hidden_fields: []
  ]
end
