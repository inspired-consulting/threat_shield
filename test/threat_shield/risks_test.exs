defmodule ThreatShield.RisksTest do
  use ExUnit.Case
  use ThreatShield.DataCase

  alias ThreatShield.ThreatsFixtures
  alias ThreatShield.OrganisationsFixtures
  alias ThreatShield.AccountsFixtures
  alias ThreatShield.Risks
  alias ThreatShield.Risks.Risk

  describe "risks" do
    test "create_risk/3 - creates a risk" do
      user = AccountsFixtures.user_fixture()
      organisation = OrganisationsFixtures.organisation_fixture(user)
      threat = ThreatsFixtures.threat_fixture(user, organisation)
      valid_attrs = %{name: "some name", description: "some description"}

      assert {:ok, %Risk{}} = Risks.create_risk(user, threat.id, valid_attrs)
    end
  end
end
