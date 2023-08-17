defmodule ThreatShield.Repo.Migrations.ModifyOrganisationAttributes do
  use Ecto.Migration

  def up do
    alter table(:organisations) do
      remove :industry
      remove :legal_form
      remove :type_of_business
      remove :size
      remove :financial_information
    end

    alter table(:organisations) do
      add :attributes, :map
    end
  end

  def down do
    alter table(:organisations) do
      add :industry, :string
      add :legal_form, :string
      add :type_of_business, :string
      add :size, :string
      add :financial_information, :string
    end

    alter table(:organisations) do
      remove :attributes
    end
  end
end
