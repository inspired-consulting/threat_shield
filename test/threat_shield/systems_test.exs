defmodule ThreatShield.SystemsTest do
  use ExUnit.Case
  use ThreatShield.DataCase

  alias ThreatShield.Systems
  alias ThreatShield.Systems.System
  alias ThreatShield.AccountsFixtures
  alias ThreatShield.OrganisationsFixtures

  describe "systems" do
    test "create_system/3 with valid data creates a system" do
      user = AccountsFixtures.user_fixture()
      organisation = OrganisationsFixtures.organisation_fixture(user)
      valid_attrs = %{name: "some name", description: "some description"}

      assert {:ok, %System{}} = Systems.create_system(user, organisation, valid_attrs)
    end
  end
end
