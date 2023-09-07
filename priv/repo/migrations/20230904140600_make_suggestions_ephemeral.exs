defmodule ThreatShield.Repo.Migrations.MakeSuggestionsEphemeral do
  use Ecto.Migration

  def up do
    alter table("threats") do
      remove :is_candidate
    end

    alter table("assets") do
      remove :is_candidate
    end

    alter table("risks") do
      remove :is_candidate
    end
  end

  def down do
    alter table("threats") do
      add :is_candidate, :boolean, default: false, null: false
    end

    alter table("assets") do
      add :is_candidate, :boolean, default: false, null: false
    end

    alter table("risks") do
      add :is_candidate, :boolean, default: false, null: false
    end
  end
end
