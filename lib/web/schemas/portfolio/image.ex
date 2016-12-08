defmodule Brando.Portfolio.Image do
  @moduledoc """
  Ecto schema for the Image schema
  and helper functions for dealing with the schema.
  """

  @type t :: %__MODULE__{}

  use Brando.Web, :schema
  use Brando.Sequence, :schema

  alias Brando.User
  alias Brando.Portfolio.ImageSeries

  import Brando.Portfolio.Gettext
  import Brando.Images.Optimize
  import Brando.Utils.Schema, only: [put_creator: 2]

  @required_fields ~w(image image_series_id)a
  @optional_fields ~w(sequence creator_id)a

  schema "portfolio_images" do
    field :image, Brando.Type.Image
    belongs_to :creator, User
    belongs_to :image_series, ImageSeries
    field :cover, :boolean, default: :false
    sequenced
    timestamps
  end

  @doc """
  Casts and validates `params` against `schema` to create a valid
  changeset when action is :create.

  ## Example

      schema_changeset = changeset(%__MODULE__{}, :create, params)

  """
  @spec changeset(t, atom, Keyword.t | Options.t) :: t
  def changeset(schema, :create, params) do
    schema
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> optimize(:image)
  end

  @doc """
  Casts and validates `params` against `schema` to create a valid
  changeset when action is :update.

  ## Example

      schema_changeset = changeset(%__MODULE__{}, :update, params)

  """
  @spec changeset(t, atom, %{binary => term} | %{atom => term}) :: t
  def changeset(schema, :update, params) do
    schema
    |> cast(params, @required_fields ++ @optional_fields)
    |> optimize(:image)
  end

  @doc """
  Create a new image
  We keep this coupled since it's used for the automatic image upload.
  """
  @spec create(%{binary => term} | %{atom => term}, User.t) :: {:ok, t} | {:error, Keyword.t}
  def create(params, current_user) do
    schema_changeset = %__MODULE__{}
                      |> put_creator(current_user)
                      |> changeset(:create, params)

    Brando.repo.insert(schema_changeset)
  end

  @doc """
  Update image
  We keep this coupled since it's used for the automatic image upload.
  """
  @spec update(t, %{binary => term} | %{atom => term}) :: {:ok, t} | {:error, Keyword.t}
  def update(schema, params) do
    schema_changeset = changeset(schema, :update, params)
    Brando.repo.update(schema_changeset)
  end

  @doc """
  Get all images in series `id`.
  Used for sequence filtering.
  """
  def for_series_id(id) do
    from i in __MODULE__,
      where: i.image_series_id == ^id,
      order_by: i.sequence
  end

  #
  # Meta

  use Brando.Meta.Schema, [
    singular: gettext("image"),
    plural: gettext("images"),
    repr: &("#{&1.id} | #{&1.image.path}"),
    fields: [
      id: gettext("ID"),
      image: gettext("Image"),
      sequence: gettext("Sequence"),
      creator: gettext("Creator"),
      image_series: gettext("Image series"),
      inserted_at: gettext("Inserted at"),
      updated_at: gettext("Updated at")
    ],
  ]
end
