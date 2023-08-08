defmodule ThreatShield.Repo.Migrations.CreateOrganisations do
  use Ecto.Migration

  def change do
    create table(:organisations) do
      add(:name, :string, null: false)
      add(:industry, :string)
      add(:legal_form, :string)
      add(:location, :string)
      add(:type_of_business, :string)
      add(:size, :integer)
      add(:financial_information, :string)

      timestamps()
    end

    create table(:memberships) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:organisation_id, references(:organisations, on_delete: :delete_all), null: false)
    end

    create unique_index(:memberships, [:user_id, :organisation_id])
  end
end
