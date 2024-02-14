defmodule ThreatShield.Repo.Migrations.CreateAssets do
  use Ecto.Migration

  def change do
    create table(:assets) do
      add :name, :string, null: false, size: 255
      add :description, :string, size: 4000
      add :criticality_loss, :float
      add :criticality_theft, :float
      add :criticality_publication, :float
      add :criticality_overall, :float

      add :organisation_id, references(:organisations, on_delete: :delete_all), null: false
      add :system_id, references(:systems, on_delete: :nothing)

      timestamps()
    end

    create index(:assets, [:organisation_id])
    create index(:assets, [:system_id])
  end
end
