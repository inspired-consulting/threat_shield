defmodule ThreatShield.Members do
  @moduledoc """
  The Members context.
  """

  import Ecto.Query, warn: false
  alias ThreatShield.Organisations.Membership
  alias ThreatShield.Organisations.Organisation
  alias ThreatShield.Repo

  alias ThreatShield.Members.Invite
  alias ThreatShield.Accounts.User
  alias ThreatShield.Organisations.Organisation

  import ThreatShieldWeb.Helpers, only: [generate_token: 0]

  def get_organisation!(%User{id: user_id}, org_id) do
    Organisation.get(org_id)
    |> Organisation.for_user(user_id)
    |> Organisation.with_memberships()
    |> Organisation.with_invites()
    |> Repo.one()
  end

  def get_invite_by_token(token) do
    Invite.from()
    |> Invite.for_token(token)
    |> Invite.with_organisation()
    |> Invite.with_time_limit()
    |> Repo.one()
  end

  def join_with_token(%User{} = user, token) do
    case Repo.transaction(fn ->
           invite = get_invite_by_token(token)

           if not is_nil(invite) do
             membership =
               %Membership{user: user, organisation: invite.organisation, role: :viewer}
               |> Repo.insert!()

             Repo.delete(invite)
             {:ok, membership}
           else
             {:error, :invalid_token}
           end
         end) do
      {:ok, {:ok, membership}} -> {:ok, membership}
      {:ok, {:error, err}} -> {:error, err}
      {:error, err} -> {:error, err}
    end
  end

  def create_invite(%User{id: user_id}, %Organisation{id: org_id}, attrs \\ %{}) do
    token = generate_token()

    case Repo.transaction(fn ->
           organisation =
             Organisation.get(org_id)
             |> Organisation.for_user(user_id, :invite_new_members)
             |> Repo.one!()

           %Invite{token: token}
           |> Invite.changeset(attrs)
           |> Ecto.Changeset.put_assoc(:organisation, organisation)
           |> Repo.insert()
         end) do
      {:ok, {:ok, invite}} -> {:ok, invite}
      {:ok, {:error, changeset}} -> {:error, changeset}
      {:error, err} -> {:error, err}
    end
  end

  def delete_membership_by_id(%User{id: user_id}, org_id, membership_id) do
    case Repo.transaction(fn ->
           organisation =
             Organisation.get(org_id)
             |> Organisation.for_user(user_id, :delete_member)
             |> Organisation.with_memberships()
             |> Repo.one!()

           if length(organisation.memberships |> Enum.filter(fn m -> m.role == :owner end)) >= 2 do
             Membership.get(membership_id)
             |> Membership.for_user(user_id)
             |> Membership.select()
             |> Repo.delete_all()
           else
             {:error, :last_member}
           end
         end) do
      {:ok, {1, [membership]}} -> {:ok, membership}
      {:ok, {:error, err}} -> {:error, err}
      {:error, err} -> {:error, err}
    end
  end

  def delete_invite_by_id(%User{id: user_id}, invite_id) do
    case Invite.get(invite_id)
         |> Invite.for_user(user_id, :invite_new_members)
         |> Invite.select()
         |> Repo.delete_all() do
      {1, [invite]} -> {:ok, invite}
      _ -> {:error}
    end
  end

  def delete_expired_invites() do
    Invite.from()
    |> Invite.where_expired()
    |> Invite.select()
    |> Repo.delete_all()
  end

  def update_invite(%Invite{} = invite, attrs) do
    invite
    |> Invite.changeset(attrs)
    |> Repo.update()
  end

  def change_invite(%Invite{} = invite, attrs \\ %{}) do
    Invite.changeset(invite, attrs)
  end

  def change_membership(%Membership{} = membership, attrs \\ %{}) do
    Membership.changeset(membership, attrs)
  end

  def update_role(%User{id: user_id}, %Membership{id: membership_id}, role) do
    case Repo.transaction(fn ->
           old_membership =
             Membership.get(membership_id)
             |> Membership.for_user(user_id, :edit_membership)
             |> Membership.preload_org_memberships()
             |> Repo.one()

           num_owners =
             length(
               Enum.filter(old_membership.organisation.memberships, fn m -> m.role == :owner end)
             )

           if old_membership.role == :owner and num_owners <= 1 do
             {:error, :last_owner}
           else
             old_membership
             |> Membership.changeset(%{"role" => role})
             |> Repo.update()
           end
         end) do
      {:ok, {:ok, membership}} -> {:ok, membership}
      {:ok, {:error, e}} -> {:error, e}
      {:error, e} -> {:error, e}
    end
  end
end
