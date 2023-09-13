defmodule ThreatShield.Repo.Migrations.AddDeleteHookForSystemThreatRelation do
  use Ecto.Migration

  def change do
    alter table(:threats) do
      modify :system_id, references(:systems, on_delete: :delete_all),
        from: references(:systems, on_delete: :nothing)
    end
  end
end
