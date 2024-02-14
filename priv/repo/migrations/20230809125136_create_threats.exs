defmodule ThreatShield.Repo.Migrations.CreateThreats do
  use Ecto.Migration

  def change do
    create table(:threats) do
      add :organisation_id, references(:organisations, on_delete: :delete_all), null: false
      add :name, :string, null: false, size: 255
      add :description, :string, size: 4000
      add :system_id, references(:systems, on_delete: :nothing)
      add :asset_id, references(:assets, on_delete: :nothing)

      timestamps()
    end

    create index(:threats, [:system_id])
  end
end
