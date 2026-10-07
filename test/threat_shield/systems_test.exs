defmodule ThreatShield.SystemsTest do
  use ExUnit.Case
  use ThreatShield.DataCase

  alias ThreatShield.Systems
  alias ThreatShield.Systems.System
  alias ThreatShield.AccountsFixtures
  alias ThreatShield.AssetsFixtures
  alias ThreatShield.OrganisationsFixtures
  alias ThreatShield.RisksFixtures
  alias ThreatShield.ThreatsFixtures
  alias ThreatShield.Assets.Asset
  alias ThreatShield.Risks.Risk
  alias ThreatShield.Threats.Threat

  describe "systems" do
    test "create_system/3 with valid data creates a system" do
      user = AccountsFixtures.user_fixture()
      organisation = OrganisationsFixtures.organisation_fixture(user)
      valid_attrs = %{name: "some name", description: "some description"}

      assert {:ok, %System{} = system} = Systems.create_system(user, organisation, valid_attrs)

      assert system.attributes == %{}
      assert Repo.get!(System, system.id).attributes == %{}
      assert System.describe(system) =~ "some name"
    end

    test "delete_sys_by_id!/2 deletes the assets and threats of the system" do
      user = AccountsFixtures.user_fixture()
      organisation = OrganisationsFixtures.organisation_fixture(user)

      {:ok, system} =
        Systems.create_system(user, organisation, %{name: "a system", description: "d"})

      asset = AssetsFixtures.asset_fixture(user, organisation, %{system_id: system.id})

      threat =
        ThreatsFixtures.threat_fixture(user, organisation, %{
          system_id: system.id,
          asset_id: asset.id
        })

      risk = RisksFixtures.risk_fixture(user, threat.id)
      other_threat = ThreatsFixtures.threat_fixture(user, organisation, %{name: "other"})

      assert {1, _} = Systems.delete_sys_by_id!(user, system.id)

      refute Repo.get(System, system.id)
      refute Repo.get(Asset, asset.id)
      refute Repo.get(Threat, threat.id)
      refute Repo.get(Risk, risk.id)
      assert Repo.get(Threat, other_threat.id)
    end
  end
end
