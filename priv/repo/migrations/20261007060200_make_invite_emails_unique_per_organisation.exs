defmodule ThreatShield.Repo.Migrations.MakeInviteEmailsUniquePerOrganisation do
  use Ecto.Migration

  def up do
    # keep the newest invite when an address was invited twice
    execute """
    DELETE FROM invites a USING invites b
    WHERE a.organisation_id = b.organisation_id
      AND lower(a.email) = lower(b.email)
      AND a.id < b.id
    """

    # the same type as users.email, so that the addresses compare case-insensitively
    alter table(:invites) do
      modify :email, :citext, from: :string
    end

    create unique_index(:invites, [:organisation_id, :email])
  end

  def down do
    drop unique_index(:invites, [:organisation_id, :email])

    alter table(:invites) do
      modify :email, :string, from: :citext
    end
  end
end
