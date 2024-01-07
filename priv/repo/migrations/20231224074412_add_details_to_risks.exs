defmodule ThreatShield.Repo.Migrations.AddDetailsToRisks do
  use Ecto.Migration

  def change do
    alter table(:risks) do
      add :severity, :float
      add :status, :string, default: "identified"
    end
  end
end
