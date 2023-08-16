defmodule ThreatShield.Repo.Migrations.ModifyThreatsIsAccepted do
  use Ecto.Migration

  def change do
    rename table(:threats), :is_accepted, to: :is_candidate
  end
end
