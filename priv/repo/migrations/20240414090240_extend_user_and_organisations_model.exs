defmodule ThreatShield.Repo.Migrations.ExtendUserAndOrganisationsModel do
  use Ecto.Migration

  def change do
    alter table(:organisations) do
      add :quotas, :map, default: %{ai_requests_per_month: 100}
    end

    alter table(:users) do
      add :global_roles, {:array, :string}, default: []
    end
  end
end
