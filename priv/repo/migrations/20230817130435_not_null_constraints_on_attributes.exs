defmodule ThreatShield.Repo.Migrations.NotNullConstraintsOnAttributes do
  use Ecto.Migration

  def up do
    alter table("systems") do
      modify :attributes, :map, null: false, default: %{}
    end

    alter table("organisations") do
      modify :attributes, :map, null: false, default: %{}
    end
  end

  def down do
    alter table("systems") do
      modify :attributes, :map
    end

    alter table("organisations") do
      modify :attributes, :map
    end
  end
end
