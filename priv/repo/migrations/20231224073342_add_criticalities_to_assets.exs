defmodule ThreatShield.Repo.Migrations.AddCriticalitiesToAssets do
  use Ecto.Migration

  def change do
    alter table(:assets) do
      add :criticality_loss, :float
      add :criticality_theft, :float
      add :criticality_publication, :float
      add :criticality_overall, :float
    end
  end
end
