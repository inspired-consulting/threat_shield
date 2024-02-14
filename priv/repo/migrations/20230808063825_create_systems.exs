defmodule ThreatShield.Repo.Migrations.CreateSystems do
  use Ecto.Migration

  def change do
    create table(:systems) do
      add :organisation_id, references(:organisations, on_delete: :delete_all), null: false
      add :name, :string, null: false, size: 255
      add :description, :string, size: 4000
      add :attributes, :map

      timestamps()
    end

    create unique_index(:systems, [:organisation_id, :name])
  end
end
