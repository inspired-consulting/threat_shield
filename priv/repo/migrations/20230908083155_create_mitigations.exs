defmodule ThreatShield.Repo.Migrations.CreateMitigations do
  use Ecto.Migration

  def change do
    create table(:mitigations) do
      add :name, :string, null: false
      add :description, :text, null: false
      add :is_implemented, :boolean, default: false, null: false
      add :risk_id, references(:risks, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:mitigations, [:risk_id])
  end
end
