defmodule ThreatShield.ThreatsTest do
  use ExUnit.Case
  use ThreatShield.DataCase

  alias ThreatShield.OrganisationsFixtures
  alias ThreatShield.AccountsFixtures
  alias ThreatShield.Threats
  alias ThreatShield.Threats.Threat

  describe "threats" do
    test "create_threat/3 with valid data creates a threat" do
      user = AccountsFixtures.user_fixture()
      organisation = OrganisationsFixtures.organisation_fixture(user)

      valid_attrs = %{
        description: "some description",
        is_candidate: false,
        organisation: "some organisation"
      }

      assert {:ok, %Threat{}} = Threats.create_threat(user, organisation, valid_attrs)
    end
  end
end
