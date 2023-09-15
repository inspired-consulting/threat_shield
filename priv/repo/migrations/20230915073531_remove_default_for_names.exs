defmodule ThreatShield.Repo.Migrations.RemoveDefaultForNames do
  use Ecto.Migration

  def change do
    alter table(:systems) do
      modify :name, :string,
        size: 60,
        null: false,
        default: nil,
        from: {:string, size: 60, null: false, default: "CHANGEME"}
    end

    alter table(:risks) do
      modify :name, :string,
        size: 60,
        null: false,
        default: nil,
        from: {:string, size: 60, null: false, default: "CHANGEME"}
    end

    alter table(:mitigations) do
      modify :name, :string,
        size: 60,
        null: false,
        default: nil,
        from: {:string, size: 60, null: false, default: "CHANGEME"}
    end

    alter table(:threats) do
      modify :name, :string,
        size: 60,
        null: false,
        default: nil,
        from: {:string, size: 60, null: false, default: "CHANGEME"}
    end

    alter table(:assets) do
      modify :name, :string,
        size: 60,
        null: false,
        default: nil,
        from: {:string, size: 60, null: false, default: "CHANGEME"}
    end
  end
end
