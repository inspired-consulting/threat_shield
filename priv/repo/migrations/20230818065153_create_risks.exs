defmodule ThreatShield.Repo.Migrations.CreateRisks do
  use Ecto.Migration

  def change do
    create table(:risks) do
      add :name, :string, null: false
      add :description, :text, null: false
      add :estimated_cost, :integer
      add :probability, :float
      add :is_candidate, :boolean, default: false, null: false
      add :threat_id, references(:threats, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:risks, [:threat_id])
  end
end
