defmodule ThreatShield.Repo.Migrations.AddDeleteRulesForSystemAndAssetReferences do
  use Ecto.Migration

  # Deleting a system deletes its assets and threats. Deleting an asset keeps its
  # threats and removes the reference. See docs/adr/0001-delete-rules-for-system-and-asset-references.md
  def change do
    alter table(:assets) do
      modify :system_id, references(:systems, on_delete: :delete_all),
        from: references(:systems, on_delete: :nothing)
    end

    alter table(:threats) do
      modify :system_id, references(:systems, on_delete: :delete_all),
        from: references(:systems, on_delete: :nothing)

      modify :asset_id, references(:assets, on_delete: :nilify_all),
        from: references(:assets, on_delete: :nothing)
    end
  end
end
