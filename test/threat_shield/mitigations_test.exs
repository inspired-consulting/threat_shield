defmodule ThreatShield.MitigationsTest do
  alias ThreatShield.RisksFixtures
  use ThreatShield.DataCase

  alias ThreatShield.Mitigations
  alias ThreatShield.AccountsFixtures
  alias ThreatShield.OrganisationsFixtures
  alias ThreatShield.ThreatsFixtures
  alias ThreatShield.RisksFixtures

  @create_attrs %{
    name: "some name",
    description: "some description",
    estimated_cost: 42,
    probability: 120.5
  }

  defp user_risk_fixture() do
    user = AccountsFixtures.user_fixture()
    organisation = OrganisationsFixtures.organisation_fixture(user)
    threat = ThreatsFixtures.threat_fixture(user, organisation)
    risk = RisksFixtures.risk_fixture(user, threat.id, @create_attrs)
    %{user: user, risk: risk}
  end

  describe "mitigations" do
    alias ThreatShield.Mitigations.Mitigation

    @invalid_attrs %{name: nil, description: nil, is_implemented: nil}

    test "create_mitigation/1 with valid data creates a mitigation" do
      valid_attrs = %{name: "some name", description: "some description", is_implemented: true}
      %{user: user, risk: risk} = user_risk_fixture()

      assert {:ok, %Mitigation{} = mitigation} =
               Mitigations.create_mitigation(user, risk, valid_attrs)

      assert mitigation.name == "some name"
      assert mitigation.description == "some description"
      assert mitigation.is_implemented == true
    end

    test "create_mitigation/1 with invalid data returns error changeset" do
      %{user: user, risk: risk} = user_risk_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Mitigations.create_mitigation(user, risk, @invalid_attrs)
    end
  end
end
