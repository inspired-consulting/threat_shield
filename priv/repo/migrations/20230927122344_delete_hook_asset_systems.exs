defmodule ThreatShield.Repo.Migrations.DeleteHookAssetSystems do
  use Ecto.Migration

  def change do
    alter table(:assets) do
      modify :system_id, references(:systems, on_delete: :delete_all),
        from: references(:systems, on_delete: :nothing)
    end
  end
end
