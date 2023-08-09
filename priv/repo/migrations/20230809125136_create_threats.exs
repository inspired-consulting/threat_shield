defmodule ThreatShield.Repo.Migrations.CreateThreats do
  use Ecto.Migration

  def change do
    create table(:threats) do
      add :description, :string
      add :is_accepted, :boolean, default: false, null: false
      add :system_id, references(:systems, on_delete: :nothing)

      timestamps()
    end

    create index(:threats, [:system_id])
  end
end
