defmodule ThreatShield.Repo.Migrations.AddImplementatationDetailsToMitigations do
  use Ecto.Migration

  def change do
    alter table(:mitigations) do
      add :status, :string, default: "open"
      add :implementation_notes, :string
      add :implementation_date, :date
      add :verification_date, :date
      add :verification_method, :string
      add :verification_result, :string
      add :issue_link, :string
    end
  end
end
