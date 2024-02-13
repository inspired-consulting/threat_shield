defmodule ThreatShield.Repo.Migrations.CreateMitigations do
  use Ecto.Migration

  def change do
    create table(:mitigations) do
      add :name, :string, null: false, size: 255
      add :description, :string, size: 4000
      add :is_implemented, :boolean, default: false, null: false
      add :status, :string, default: "open"
      add :implementation_notes, :string
      add :implementation_date, :date
      add :verification_date, :date
      add :verification_method, :string
      add :verification_result, :string
      add :issue_link, :string

      add :risk_id, references(:risks, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:mitigations, [:risk_id])
  end
end
