defmodule <%= application_module %>.Repo.Migrations.CreatePortfolioImages do
  use Ecto.Migration
  use Brando.Sequence, :migration

  def up do
    create table(:portfolio_images) do
      add :image,             :text
      add :cover,             :boolean, default: false
      add :creator_id,        references(:users)
      add :image_series_id,   references(:portfolio_imageseries)
      sequenced
      timestamps
    end
  end

  def down do
    drop table(:portfolio_images)
  end
end
