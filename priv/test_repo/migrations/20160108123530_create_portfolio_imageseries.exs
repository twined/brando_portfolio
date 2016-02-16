defmodule BrandoPortfolio.Repo.Migrations.CreatePortfolioImageseries do
  use Ecto.Migration
  use Brando.Sequence, :migration
  use Brando.Villain, :migration

  def up do
    create table(:portfolio_imageseries) do
      add :name,              :text
      add :slug,              :text
      add :cfg,               :json
      villain
      add :creator_id,        references(:users)
      add :image_category_id, references(:portfolio_imagecategories)
      sequenced
      timestamps
    end
    create index(:portfolio_imageseries, [:slug])
  end

  def down do
    drop table(:portfolio_imageseries)
    drop index(:portfolio_imageseries, [:slug])
    drop index(:portfolio_imageseries, [:order])
  end
end
