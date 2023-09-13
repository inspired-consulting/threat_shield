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

  def create_invite(%User{id: user_id}, %Organisation{id: org_id}, attrs \\ %{}) do
    token = generate_token()

    case Repo.transaction(fn ->
           organisation =
             Organisation.get(org_id)
             |> Organisation.for_user(user_id)
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
             |> Organisation.for_user(user_id)
             |> Organisation.with_memberships()
             |> Repo.one!()

           if length(organisation.memberships) >= 2 do
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
         |> Invite.for_user(user_id)
         |> Invite.select()
         |> Repo.delete_all() do
      {1, [invite]} -> {:ok, invite}
      _ -> {:error}
    end
  end

  def update_invite(%Invite{} = invite, attrs) do
    invite
    |> Invite.changeset(attrs)
    |> Repo.update()
  end

  def change_invite(%Invite{} = invite, attrs \\ %{}) do
    Invite.changeset(invite, attrs)
  end
end
