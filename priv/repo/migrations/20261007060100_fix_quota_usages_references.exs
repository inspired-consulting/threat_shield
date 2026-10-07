defmodule ThreatShield.Repo.Migrations.FixQuotaUsagesReferences do
  use Ecto.Migration

  def up do
    # user_id referenced organisations by mistake. The stored values are user ids.
    execute """
    UPDATE quota_usages SET user_id = NULL
    WHERE user_id IS NOT NULL AND user_id NOT IN (SELECT id FROM users)
    """

    alter table(:quota_usages) do
      modify :user_id, references(:users, on_delete: :nilify_all),
        from: references(:organisations)

      modify :organisation_id, references(:organisations, on_delete: :delete_all),
        from: references(:organisations)

      modify :timestamp, :utc_datetime_usec, default: fragment("now()")
    end

    create index(:quota_usages, [:organisation_id])
    create index(:quota_usages, [:user_id])

    # left over from an earlier version of the quota model
    alter table(:organisations) do
      remove_if_exists :quota_period, :string
    end
  end

  def down do
    drop index(:quota_usages, [:user_id])
    drop index(:quota_usages, [:organisation_id])

    alter table(:quota_usages) do
      modify :timestamp, :utc_datetime_usec, default: nil

      modify :organisation_id, references(:organisations),
        from: references(:organisations, on_delete: :delete_all)

      modify :user_id, references(:organisations),
        from: references(:users, on_delete: :nilify_all)
    end
  end
end
