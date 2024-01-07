defmodule ThreatShield.Repo.Migrations.AddAssetToThreat do
  use Ecto.Migration

  def change do
    alter table(:threats) do
      add :asset_id, references(:assets, on_delete: :nothing)
    end
  end
end
