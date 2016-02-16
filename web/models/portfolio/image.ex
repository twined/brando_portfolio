defmodule Brando.Portfolio.Image do
  @moduledoc """
  Ecto schema for the Image model
  and helper functions for dealing with the model.
  """

  @type t :: %__MODULE__{}

  use Brando.Web, :model
  use Brando.Images.Upload
  use Brando.Sequence, :model

  alias Brando.User
  alias Brando.Portfolio.ImageSeries

  import Brando.Gettext
  import Brando.Utils.Model, only: [put_creator: 2]

  @required_fields ~w(image image_series_id)
  @optional_fields ~w(sequence creator_id)

  schema "portfolio_images" do
    field :image, Brando.Type.Image
    belongs_to :creator, User
    belongs_to :image_series, ImageSeries
    field :cover, :boolean, default: :false
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
  def changeset(model, :create, params) do
    cast(model, params, @required_fields, @optional_fields)
  end

  @doc """
  Casts and validates `params` against `model` to create a valid
  changeset when action is :update.

  ## Example

      model_changeset = changeset(%__MODULE__{}, :update, params)

  """
  @spec changeset(t, atom, %{binary => term} | %{atom => term}) :: t
  def changeset(model, :update, params) do
    cast(model, params, [], @required_fields ++ @optional_fields)
  end

  @doc """
  Create a new image
  We keep this coupled since it's used for the automatic image upload.
  """
  @spec create(%{binary => term} | %{atom => term}, User.t) :: {:ok, t} | {:error, Keyword.t}
  def create(params, current_user) do
    model_changeset =
      %__MODULE__{}
      |> put_creator(current_user)
      |> changeset(:create, params)

    Brando.repo.insert(model_changeset)
  end

  @doc """
  Update image
  We keep this coupled since it's used for the automatic image upload.
  """
  @spec update(t, %{binary => term} | %{atom => term}) :: {:ok, t} | {:error, Keyword.t}
  def update(model, params) do
    model_changeset = changeset(model, :update, params)
    Brando.repo.update(model_changeset)
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

  use Brando.Meta.Model, [
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
