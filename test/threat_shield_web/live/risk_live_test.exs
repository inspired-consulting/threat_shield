defmodule ThreatShieldWeb.RiskLiveTest do
  use ThreatShieldWeb.ConnCase

  #  import Phoenix.LiveViewTest
  import ThreatShield.RisksFixtures

  alias ThreatShield.AccountsFixtures
  alias ThreatShield.OrganisationsFixtures
  alias ThreatShield.ThreatsFixtures

  @create_attrs %{
    name: "some name",
    description: "some description",
    estimated_cost: 42,
    probability: 120.5
  }

  defp create_risk(_) do
    user = AccountsFixtures.user_fixture()
    organisation = OrganisationsFixtures.organisation_fixture(user)
    threat = ThreatsFixtures.threat_fixture(user, organisation)
    risk = risk_fixture(user, threat.id, @create_attrs)
    %{user: user, risk: risk}
  end

  describe "Index" do
    setup [:create_risk]
  end
end
