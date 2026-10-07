defmodule ThreatShield.Repo.Migrations.AddMissingIndexesAndSystemAttributesDefault do
  use Ecto.Migration

  def up do
    create index(:threats, [:organisation_id])
    create index(:threats, [:asset_id])
    create index(:memberships, [:organisation_id])

    # systems.attributes is read as a map everywhere; it must not be NULL
    execute "UPDATE systems SET attributes = '{}' WHERE attributes IS NULL"

    alter table(:systems) do
      modify :attributes, :map, null: false, default: %{}
    end
  end

  def down do
    alter table(:systems) do
      modify :attributes, :map, null: true, default: nil
    end

    drop index(:memberships, [:organisation_id])
    drop index(:threats, [:asset_id])
    drop index(:threats, [:organisation_id])
  end
end
