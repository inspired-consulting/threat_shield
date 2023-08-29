defmodule ThreatShield.AssetsTest do
  use ExUnit.Case
  use ThreatShield.DataCase

  alias ThreatShield.OrganisationsFixtures
  alias ThreatShield.AccountsFixtures
  alias ThreatShield.Assets
  alias ThreatShield.Assets.Asset

  describe "assets" do
    test "create_asset/3 with valid data creates an asset" do
      user = AccountsFixtures.user_fixture()
      organisation = OrganisationsFixtures.organisation_fixture(user)
      valid_attrs = %{description: "some description", organisation: "some organisation"}

      assert {:ok, %Asset{}} = Assets.create_asset(user, organisation, valid_attrs)
    end
  end
end
