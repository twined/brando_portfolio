defmodule Brando.Portfolio.ImageSeries do
  @moduledoc """
  Ecto schema for the Image Series model
  and helper functions for dealing with the model.
  """

  @type t :: %__MODULE__{}

  use Brando.Web, :model
  use Brando.Sequence, :model
  use Brando.Villain, :model

  alias Brando.User
  alias Brando.Portfolio.Image
  alias Brando.Portfolio.ImageCategory

  import Brando.Gettext
  import Ecto.Query, only: [from: 2]
  import Brando.Utils.Model, only: [put_creator: 2]

  @required_fields ~w(name slug image_category_id creator_id)
  @optional_fields ~w(sequence cfg data html)

  schema "portfolio_imageseries" do
    field :name, :string
    field :slug, :string
    villain
    field :cfg, Brando.Type.ImageConfig
    belongs_to :creator, User
    belongs_to :image_category, ImageCategory
    has_many :images, Image
    sequenced
    timestamps
  end

  @doc """
  Casts and validates `params` against `model` to create a valid
  changeset when action is :create.

  ## Example

      model_changeset = changeset(%__MODULE__{}, :create, params)

  """
  @spec changeset(t, atom, Keyword.t | Options.t) :: t
  def changeset(model, action, params \\ :empty)
  def changeset(model, :create, params) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> generate_html()
    |> inherit_configuration()
  end

  @doc """
  Casts and validates `params` against `model` to create a valid
  changeset when action is :update.

  ## Example

      model_changeset = changeset(%__MODULE__{}, :update, params)

  """
  @spec changeset(t, atom, Keyword.t | Options.t) :: t
  def changeset(model, :update, params) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> generate_html()
  end

  @doc """
  Create a changeset for the model by passing `params`.
  If valid, generate a hashed password and insert model to Brando.repo.
  If not valid, return errors from changeset
  """
  def create(params, current_user) do
    %__MODULE__{}
    |> put_creator(current_user)
    |> changeset(:create, params)
    |> Brando.repo.insert
  end

  @doc """
  Create an `update` changeset for the model by passing `params`.
  If password is in changeset, hash and insert in changeset.
  If valid, update model in Brando.repo.
  If not valid, return errors from changeset
  """
  def update(model, params) do
    model
    |> changeset(:update, params)
    |> Brando.repo.update
  end

  def get_slug(id: id) do
    q = from m in __MODULE__,
             select: m.slug,
             where: m.id == ^id
    Brando.repo.one!(q)
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
    cat_id = Ecto.Changeset.get_field(cs, :image_category_id)
    slug = Ecto.Changeset.get_field(cs, :slug)

    category = Brando.repo.get(ImageCategory, cat_id)

    cfg =
      if slug do
        Map.put(category.cfg, :upload_path, Path.join(Map.get(category.cfg, :upload_path), slug))
      else
        category.cfg
      end

    put_change(cs, :cfg, cfg)
  end

  #
  # Meta

  use Brando.Meta.Model, [
    singular: gettext("imageserie"),
    plural: gettext("imageseries"),
    repr: fn (model) ->
       model = Brando.repo.preload(model, :images)
       image_count = Enum.count(model.images)
       "#{model.name} – #{image_count} #{gettext("image(s)")}."
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
    hidden_fields: []
  ]
end