defmodule ThreatShield.AssetsTest do
  use ExUnit.Case
  use ThreatShield.DataCase

  alias ThreatShield.OrganisationsFixtures
  alias ThreatShield.AccountsFixtures
  alias ThreatShield.AssetsFixtures
  alias ThreatShield.ThreatsFixtures
  alias ThreatShield.Threats.Threat
  alias ThreatShield.Assets
  alias ThreatShield.Assets.Asset

  describe "assets" do
    test "create_asset/3 with valid data creates an asset" do
      user = AccountsFixtures.user_fixture()
      organisation = OrganisationsFixtures.organisation_fixture(user)

      valid_attrs = %{
        name: "some_name",
        description: "some description",
        organisation: "some organisation"
      }

      assert {:ok, %Asset{}} = Assets.create_asset(user, organisation, valid_attrs)
    end

    test "delete_asset_by_id/2 keeps the threats of the asset and clears the reference" do
      user = AccountsFixtures.user_fixture()
      organisation = OrganisationsFixtures.organisation_fixture(user)
      asset = AssetsFixtures.asset_fixture(user, organisation)
      threat = ThreatsFixtures.threat_fixture(user, organisation, %{asset_id: asset.id})

      assert {1, _} = Assets.delete_asset_by_id(user, asset.id)

      refute Repo.get(Asset, asset.id)
      assert %Threat{asset_id: nil} = Repo.get(Threat, threat.id)
    end
  end
end
