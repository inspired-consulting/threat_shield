defmodule ThreatShield.AssetsTest do
  use ThreatShield.DataCase

  alias ThreatShield.Assets
  alias ThreatShield.Assets.Asset
  describe "assets" do

    import ThreatShield.AssetsFixtures

    @invalid_attrs %{is_candidate: nil, description: nil}

    test "create_asset/3 with valid data creates an asset" do
      {:ok, user} = AssetsFixtures.user_fixture()
      {:ok, organisation} = AssetsFixtures.organisation_fixture(user)
      valid_attrs = %{is_candidate: 42, description: "some description"}

      assert {:ok, %Asset{} = asset} = Assets.create_asset(user, organisation, valid_attrs)
  end
end
end
