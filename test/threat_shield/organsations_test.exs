defmodule ThreatShield.OrganisationsTest do
  use ExUnit.Case
  use ThreatShield.DataCase

  alias ThreatShield.Organisations
  alias ThreatShield.Accounts.Organisation
  alias ThreatShield.OrganisationsFixtures
  alias ThreatShield.AccountsFixtures

  describe "organisations" do
    test "create_organisation/2 with valid data creates an organisation" do
      user = AccountsFixtures.user_fixture()
      valid_attrs = %{name: "some name"}

      assert {:ok, %Organisation{}} =
               Organisations.create_organisation(valid_attrs, user)
    end

    test "create_organisation/2 with invalid data returns error changeset" do
      user = AccountsFixtures.user_fixture()

      assert {:error, %Ecto.Changeset{}} = Organisations.create_organisation(%{}, user)
    end

    test "update_organisation/3 with valid data updates the organisation" do
      user = AccountsFixtures.user_fixture()
      organisation = OrganisationsFixtures.organisation_fixture(user)

      updated_attrs = %{name: "Updated Name"}
      updated_organisation = Organisations.update_organisation(organisation, user, updated_attrs)

      assert {:ok, %Organisation{} = organisation} = updated_organisation
      assert organisation.name == "Updated Name"
    end
  end
end
