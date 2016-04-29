defmodule <%= application_module %>.Repo.Migrations.CreatePortfolioImagecategories do
  use Ecto.Migration
  use Brando.Villain, :migration

  def up do
    create table(:portfolio_imagecategories) do
      add :name,              :text
      add :slug,              :text
      add :cfg,               :json
      villain
      add :creator_id,        references(:users)
      timestamps
    end
    create unique_index(:portfolio_imagecategories, [:slug])
  end

  def down do
    drop table(:portfolio_imagecategories)
    drop index(:portfolio_imagecategories, [:slug])
  end
end
