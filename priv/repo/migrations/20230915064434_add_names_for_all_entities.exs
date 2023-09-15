defmodule ThreatShield.Repo.Migrations.AddNamesForAllEntities do
  use Ecto.Migration

  def change do
    alter table(:systems) do
      modify :name, :string,
        size: 60,
        null: false,
        default: fragment("gen_random_uuid()"),
        from: {:string, size: 255, null: true}
    end

    alter table(:risks) do
      modify :name, :string,
        size: 60,
        null: false,
        default: fragment("gen_random_uuid()"),
        from: {:string, size: 255, null: true}
    end

    alter table(:mitigations) do
      modify :name, :string,
        size: 60,
        null: false,
        default: fragment("gen_random_uuid()"),
        from: {:string, size: 255, null: true}
    end

    alter table(:threats) do
      add :name, :string, size: 60, null: false, default: fragment("gen_random_uuid()")
    end

    alter table(:assets) do
      add :name, :string, size: 60, null: false, default: fragment("gen_random_uuid()")
    end
  end
end
