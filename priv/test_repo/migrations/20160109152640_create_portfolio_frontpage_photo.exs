defmodule BrandoPortfolio.Repo.Migrations.CreatePortfolioFrontpagePhoto do
  use Ecto.Migration

  def change do
    create table(:portfolio_frontpage_photos) do
      add :photo, :text
      timestamps
    end
  end
end
