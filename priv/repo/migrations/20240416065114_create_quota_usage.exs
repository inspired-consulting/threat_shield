defmodule ThreatShield.Repo.Migrations.CreateQuotaUsage do
  use Ecto.Migration

  def change do
    create table(:quota_usages) do
      add :organisation_id, references(:organisations), null: true
      add :user_id, references(:organisations), null: true
      add :quota_type, :string
      add :amount, :float, default: 0
      add :message, :string
      add :timestamp, :utc_datetime_usec, null: false
    end
  end
end
