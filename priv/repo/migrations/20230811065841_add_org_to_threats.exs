defmodule ThreatShield.Repo.Migrations.AddOrgToThreats do
  use Ecto.Migration

  def change do
    alter table(:threats) do
      add(:organisation_id, references(:organisations, on_delete: :delete_all), null: false)
    end
  end
end
