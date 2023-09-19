defmodule ThreatShield.Repo.Migrations.AddOrgRoles do
  use Ecto.Migration

  def change do
    alter table(:memberships) do
      add :role, :string, null: false, default: "owner"
    end

    alter table(:memberships) do
      modify :role, :string,
        null: false,
        default: nil,
        from: {:string, null: false, default: "owner"}
    end
  end
end
