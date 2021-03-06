defmodule Brando.Portfolio.ImageCategory do
  @moduledoc """
  Ecto schema for the Image Category model
  and helper functions for dealing with the model.
  """

  @type t :: %__MODULE__{}

  use Brando.Web, :model
  use Brando.Villain, :model

  alias Brando.User
  alias Brando.Portfolio.ImageSeries

  import Brando.Portfolio.Gettext
  import Ecto.Query, only: [from: 2]

  @required_fields ~w(name slug creator_id)a
  @optional_fields ~w(cfg data html)a

  schema "portfolio_imagecategories" do
    field :name, :string
    field :slug, :string
    villain
    field :cfg, Brando.Type.ImageConfig
    belongs_to :creator, User
    has_many :image_series, ImageSeries
    timestamps
  end

  @doc """
  Casts and validates `params` against `model` to create a valid
  changeset when action is :create.

  ## Example

      model_changeset = changeset(%__MODULE__{}, :create, params)

  """
  @spec changeset(t, :create | :update, Keyword.t | Options.t) :: Ecto.Changeset.t
  def changeset(model, action, params \\ %{})
  def changeset(model, :create, params) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:slug)
    |> put_default_config
  end

  @doc """
  Casts and validates `params` against `model` to create a valid
  changeset when action is :update.

  ## Example

      model_changeset = changeset(%__MODULE__{}, :update, params)

  """
  def changeset(model, :update, params) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_paths
    |> unique_constraint(:slug)
  end

  @doc """
  Put default image config in changeset
  """
  @spec put_default_config(Ecto.Changeset.t) :: Ecto.Changeset.t
  def put_default_config(cs) do
    path_from_slug  = Ecto.Changeset.get_change(cs, :slug, "default")
    upload_path     = Path.join(["images", "portfolio", path_from_slug])
    fallback_config = Brando.config(Brando.Images)[:default_config]
    default_config  = :brando_portfolio
                      |> Application.get_env(:default_config, fallback_config)
                      |> Map.put(:upload_path, upload_path)

    put_change(cs, :cfg, default_config)
  end

  @doc """
  Get all records. Ordered by `id`.
  """
  @spec with_image_series_and_images(Ecto.Query.t) :: Ecto.Query.t
  def with_image_series_and_images(query) do
    from m in query,
      left_join: is in assoc(m, :image_series),
      left_join: i in assoc(is, :images),
       order_by: [asc: m.name, asc: is.sequence, asc: i.sequence],
        preload: [image_series: {is, images: i}]
  end

  @doc """
  Validate `cs` cfg upload_path if slug is changed
  """
  @spec validate_paths(Ecto.Changeset.t) :: Ecto.Changeset.t
  def validate_paths(%Ecto.Changeset{changes: %{slug: slug}} = cs) do
    old_cfg    = cs.data.cfg
    split_path = Path.split(old_cfg.upload_path)
    new_path   = split_path
                 |> List.delete_at(Enum.count(split_path) - 1)
                 |> Path.join
                 |> Path.join(slug)

    new_cfg    = Map.put(old_cfg, :upload_path, new_path)

    put_change(cs, :cfg, new_cfg)
  end

  def validate_paths(cs) do
    cs
  end

  #
  # Meta

  use Brando.Meta.Model, [
    singular: gettext("image category"),
    plural: gettext("image categories"),
    repr: &(&1.name),
    fields: [
      id: gettext("ID"),
      name: gettext("Name"),
      slug: gettext("Slug"),
      html: gettext("HTML"),
      data: gettext("Data"),
      cfg: gettext("Config"),
      creator: gettext("Creator"),
      image_series: gettext("Image series"),
      inserted_at: gettext("Inserted at"),
      updated_at: gettext("Updated at")
    ]
  ]
end
