defmodule ThreatShield.Repo.Migrations.CreateRisks do
  use Ecto.Migration

  def change do
    create table(:risks) do
      add :name, :string, null: false, size: 255
      add :description, :string, size: 4000
      add :estimated_cost, :integer
      add :probability, :float
      add :severity, :float
      add :status, :string, default: "identified"

      add :threat_id, references(:threats, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:risks, [:threat_id])
  end
end
