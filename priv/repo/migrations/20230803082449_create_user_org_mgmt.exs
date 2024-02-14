defmodule ThreatShield.Repo.Migrations.CreateUsersOrgTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:organisations) do
      add :name, :string, null: false, size: 255
      add :location, :string
      add :attributes, :map, null: false, default: %{}

      timestamps()
    end

    create table(:users) do
      add :email, :citext, null: false
      add :first_name, :string, null: true, size: 40
      add :last_name, :string, null: true, size: 40
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      timestamps()
    end

    create unique_index(:users, [:email])

    create table(:users_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])

    create table(:invites) do
      add :token, :string, null: false
      add :email, :string, null: false
      add :organisation_id, references(:organisations, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:invites, [:organisation_id])
    create unique_index(:invites, [:token])

    create table(:memberships) do
      add :role, :string, null: false, default: "viewer"
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:organisation_id, references(:organisations, on_delete: :delete_all), null: false)
    end

    create unique_index(:memberships, [:user_id, :organisation_id])
  end
end
