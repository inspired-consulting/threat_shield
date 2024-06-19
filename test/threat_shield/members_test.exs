defmodule ThreatShield.MembersTest do
  use ExUnit.Case

  use ThreatShield.DataCase

  alias ThreatShield.OrganisationsFixtures
  alias ThreatShield.AccountsFixtures
  alias ThreatShield.{Members, Accounts, Organisations}
  alias ThreatShield.Members.Invite
  alias ThreatShield.Accounts.{Organisation, Membership}

  describe "members" do
    test "can add a existing user as member to another org" do
      owner = AccountsFixtures.user_fixture()
      organisation = OrganisationsFixtures.organisation_fixture(owner)

      other_user = AccountsFixtures.user_fixture()

      {:ok, invite} = Members.create_invite(owner, organisation, %{email: other_user.email})

      assert %Invite{} = invite

      Members.accept_invite(other_user, invite.id)

      reloaded = Accounts.get_user!(other_user.id)
      assert [%Organisation{id: org_id}] = Organisations.list_organisations(reloaded)
      assert org_id == organisation.id
    end

    test "can not add a user twice to an org" do
      owner = AccountsFixtures.user_fixture()
      organisation = OrganisationsFixtures.organisation_fixture(owner)

      other_user = AccountsFixtures.user_fixture()

      {:ok, invite_1} = Members.create_invite(owner, organisation, %{email: other_user.email})
      {:ok, %Membership{}} = Members.accept_invite(other_user, invite_1.id)

      {:ok, invite_2} = Members.create_invite(owner, organisation, %{email: other_user.email})
      {:error, :already_member} = Members.accept_invite(other_user, invite_2.id)
    end
  end
end
