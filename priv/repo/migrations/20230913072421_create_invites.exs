defmodule ThreatShield.Repo.Migrations.CreateInvites do
  use Ecto.Migration

  def change do
    create table(:invites) do
      add :token, :string, null: false
      add :email, :string, null: false
      add :organisation_id, references(:organisations, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:invites, [:organisation_id])
    create unique_index(:invites, [:token])
  end
end
