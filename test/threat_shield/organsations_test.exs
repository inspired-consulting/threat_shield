defmodule ThreatShield.OrganisationsTest do
  use ExUnit.Case
  alias ThreatShield.{Organisations, Repo, Accounts}
  alias ThreatShield.Organisations.Organisation
  alias ThreatShield.OrganisationsFixtures

  setup do
    {:ok, user} = Accounts.get_user!(1)
    {:ok, _org} = Organisations.create_organisation(user, %{name: "Test Org"})
    {:ok, user: user}
  end

  test "create_organisation/2 creates a new organisation" do
    org_attrs = %{name: "New Org"}
    organisation = OrganisationsFixtures.organisation_fixture(@user, org_attrs)

    assert organisation.name == "New Org"
  end

  test "get_organisation!/2 returns the organisation with the given id" do
    organisation = OrganisationsFixtures.organisation_fixture(@user, %{name: "Another Org"})
    retrieved_organisation = Organisations.get_organisation!(@user, organisation.id)
    assert retrieved_organisation.name == "Another Org"
  end
end
