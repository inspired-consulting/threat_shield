defmodule ThreatShield.Repo.Migrations.MakeDescriptionsLonger do
  use Ecto.Migration

  def up do
    alter table(:systems) do
      modify :description, :string, size: 4000
    end

    alter table(:threats) do
      modify :description, :string, size: 4000
    end

    alter table(:assets) do
      modify :description, :string, size: 4000
    end

    alter table(:risks) do
      modify :description, :string, size: 4000
    end

    alter table(:mitigations) do
      modify :description, :string, size: 4000
    end
  end

  def down do
    alter table(:systems) do
      modify :description, :string, size: 255
    end

    alter table(:threats) do
      modify :description, :text
    end

    alter table(:assets) do
      modify :description, :text
    end

    alter table(:risks) do
      modify :description, :text
    end

    alter table(:mitigations) do
      modify :description, :text
    end
  end
end
