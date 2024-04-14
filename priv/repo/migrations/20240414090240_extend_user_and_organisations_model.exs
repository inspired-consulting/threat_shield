defmodule ThreatShield.Repo.Migrations.ExtendUserAndOrganisationsModel do
  use Ecto.Migration

  def change do
    alter table(:organisations) do
      add :ai_request_quota, :integer, default: 100
      add :quota_period, :string, default: "month"
    end

    alter table(:users) do
      add :global_roles, {:array, :string}, default: []
    end
  end
end
