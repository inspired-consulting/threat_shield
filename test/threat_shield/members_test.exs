defmodule ThreatShield.MembersTest do
  use ExUnit.Case

  use ThreatShield.DataCase

  alias ThreatShield.OrganisationsFixtures
  alias ThreatShield.AccountsFixtures
  alias ThreatShield.Members
  alias ThreatShield.Members.Invite

  describe "members" do
    test "can add a new member" do
      owner = AccountsFixtures.user_fixture()
      organisation = OrganisationsFixtures.organisation_fixture(owner)

      invite = Members.create_invite(owner, organisation, %{email: "u1@acme"})

      assert %Invite{} = invite
    end
  end
end
