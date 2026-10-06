defmodule ThreatShield.MembersTest do
  use ExUnit.Case

  use ThreatShield.DataCase

  alias ThreatShield.OrganisationsFixtures
  alias ThreatShield.AccountsFixtures
  alias ThreatShield.MembersFixtures
  alias ThreatShield.{Members, Accounts, Organisations}
  alias ThreatShield.Members.Invite
  alias ThreatShield.Accounts.{Organisation, Membership}

  describe "members" do
    test "can add a existing user as member to another org" do
      owner = AccountsFixtures.user_fixture()
      organisation = OrganisationsFixtures.organisation_fixture(owner)

      other_user = AccountsFixtures.confirmed_user_fixture()

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

      other_user = AccountsFixtures.confirmed_user_fixture()

      {:ok, invite_1} = Members.create_invite(owner, organisation, %{email: other_user.email})
      {:ok, %Membership{}} = Members.accept_invite(other_user, invite_1.id)

      {:ok, invite_2} = Members.create_invite(owner, organisation, %{email: other_user.email})
      {:error, :already_member} = Members.accept_invite(other_user, invite_2.id)
    end
  end

  describe "invites" do
    setup do
      owner = AccountsFixtures.user_fixture()
      organisation = OrganisationsFixtures.organisation_fixture(owner)
      {:ok, invite} = Members.create_invite(owner, organisation, %{email: "invited@example.com"})

      %{owner: owner, organisation: organisation, invite: invite}
    end

    test "an account with an unconfirmed email address does not see the invite and cannot accept it",
         %{invite: invite} do
      user = AccountsFixtures.user_fixture(%{email: "invited@example.com"})

      assert Members.get_invites_by_user(user) == []
      assert {:error, :email_not_confirmed} = Members.accept_invite(user, invite.id)
      assert Organisations.list_organisations(user) == []
    end

    test "an account with a confirmed email address sees the invite", %{invite: invite} do
      user = AccountsFixtures.confirmed_user_fixture(%{email: "invited@example.com"})

      assert [%Invite{id: invite_id}] = Members.get_invites_by_user(user)
      assert invite_id == invite.id
    end

    test "an invite for another email address cannot be accepted", %{invite: invite} do
      other_user = AccountsFixtures.confirmed_user_fixture()

      assert {:error, :invalid_invite} = Members.accept_invite(other_user, invite.id)
      assert Organisations.list_organisations(other_user) == []
    end

    test "only the invitee can reject an invite", %{invite: invite} do
      invitee = AccountsFixtures.confirmed_user_fixture(%{email: "invited@example.com"})
      other_user = AccountsFixtures.confirmed_user_fixture()

      assert {:error, :not_found} = Members.reject_invite(other_user, invite.id)
      assert Repo.get(Invite, invite.id)

      assert {:ok, %Invite{}} = Members.reject_invite(invitee, invite.id)
      refute Repo.get(Invite, invite.id)
    end

    test "only an owner of the organisation can revoke an invite",
         %{owner: owner, organisation: organisation, invite: invite} do
      viewer = AccountsFixtures.user_fixture()
      MembersFixtures.membership_fixture(organisation, viewer, :viewer)

      other_owner = AccountsFixtures.user_fixture()
      OrganisationsFixtures.organisation_fixture(other_owner)

      assert {:error, :not_found} = Members.revoke_invite(viewer, invite.id)
      assert {:error, :not_found} = Members.revoke_invite(other_owner, invite.id)
      assert Repo.get(Invite, invite.id)

      assert {:ok, %Invite{}} = Members.revoke_invite(owner, invite.id)
      refute Repo.get(Invite, invite.id)
    end
  end

  describe "delete_membership_by_id/3" do
    setup do
      owner = AccountsFixtures.user_fixture()
      organisation = OrganisationsFixtures.organisation_fixture(owner)
      member = AccountsFixtures.user_fixture()
      membership = MembersFixtures.membership_fixture(organisation, member, :viewer)

      %{owner: owner, organisation: organisation, member: member, membership: membership}
    end

    test "an owner can remove a member",
         %{owner: owner, organisation: organisation, membership: membership} do
      assert {:ok, %Membership{}} =
               Members.delete_membership_by_id(owner, organisation.id, membership.id)

      refute Repo.get(Membership, membership.id)
    end

    test "a viewer and an editor cannot remove a member",
         %{organisation: organisation, member: member, membership: membership} do
      editor = AccountsFixtures.user_fixture()
      MembersFixtures.membership_fixture(organisation, editor, :editor)

      assert {:error, :not_allowed} =
               Members.delete_membership_by_id(member, organisation.id, membership.id)

      assert {:error, :not_allowed} =
               Members.delete_membership_by_id(editor, organisation.id, membership.id)

      assert Repo.get(Membership, membership.id)
    end

    test "an owner of another organisation cannot remove a member",
         %{organisation: organisation, membership: membership} do
      other_owner = AccountsFixtures.user_fixture()
      other_organisation = OrganisationsFixtures.organisation_fixture(other_owner)

      assert {:error, :not_allowed} =
               Members.delete_membership_by_id(other_owner, organisation.id, membership.id)

      assert {:error, :not_allowed} =
               Members.delete_membership_by_id(other_owner, other_organisation.id, membership.id)

      assert Repo.get(Membership, membership.id)
    end

    test "the last owner cannot be removed", %{owner: owner, organisation: organisation} do
      owner_membership =
        Repo.get_by!(Membership, user_id: owner.id, organisation_id: organisation.id)

      assert {:error, :last_owner} =
               Members.delete_membership_by_id(owner, organisation.id, owner_membership.id)

      assert Repo.get(Membership, owner_membership.id)
    end
  end
end
