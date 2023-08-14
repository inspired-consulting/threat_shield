defmodule ThreatShield.Repo.Migrations.CreateAssets do
  use Ecto.Migration

  def change do
    create table(:assets) do
      add :description, :text
      add :status, :integer, null: false
      add :organisation_id, references(:organisations, on_delete: :delete_all), null: false
      add :system_id, references(:systems, on_delete: :nothing)

      timestamps()
    end

    create index(:assets, [:organisation_id])
    create index(:assets, [:system_id])
  end
end
