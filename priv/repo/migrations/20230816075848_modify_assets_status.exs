defmodule ThreatShield.Repo.Migrations.ModifyAssetsStatus do
  use Ecto.Migration

  def change do
    alter table(:assets) do
      remove :status
    end

    alter table(:assets) do
      add :is_candidate, :boolean, default: false, null: false
    end
  end
end
