defmodule ThreatShield.Members do
  @moduledoc """
  The Members context.
  """

  import Ecto.Query, warn: false

  alias ThreatShield.Accounts.{Membership, Organisation, User}
  alias ThreatShield.Repo
  alias ThreatShield.Members.Rights
  alias ThreatShield.Members.Invite

  import ThreatShieldWeb.Helpers, only: [generate_token: 0]

  require Logger

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

  def get_invites_by_user(%User{} = invitee) do
    Invite.from()
    |> Invite.where_invitee(invitee)
    |> Invite.with_organisation()
    |> Invite.with_time_limit()
    |> Repo.all()
  end

  def join_with_token(%User{} = user, token) do
    with %Invite{} = invite <- get_invite_by_token(token),
         {:ok, :no_member} <- check_membership(user, invite.organisation_id) do
      Repo.transaction(fn ->
        membership =
          %Membership{user: user, organisation: invite.organisation, role: :viewer}
          |> Repo.insert!()

        Repo.delete(invite)
        membership
      end)
    else
      {:ok, :is_member} -> {:error, :already_member}
      nil -> {:error, :invalid_token}
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

  def delete_membership_by_id(%User{} = actor, org_id, membership_id) do
    membership =
      Membership.get(membership_id)
      |> Membership.preload_org_memberships()
      |> Repo.one()

    organisation =
      Organisation.get(org_id)
      |> Organisation.with_memberships()
      |> Repo.one()

    delete_membership(actor, organisation, membership)
  end

  def delete_membership(
        %User{} = actor,
        %Organisation{} = org,
        %Membership{} = membership
      ) do
    Logger.warning(
      "User #{actor.email} is deleting membership #{membership.id} from organisation #{org.id}"
    )

    with :ok <- Rights.check_permissioned(:delete_member, actor, org),
         :ok <- assert_not_last_member(org, membership),
         :ok <- assert_not_last_owner(org, membership) do
      Repo.delete(membership)

      {:ok, membership}
    else
      {:error, :last_owner} -> {:error, :last_owner}
      {:error, :not_allowed} -> {:error, :not_allowed}
    end
  end

  def accept_invite(%User{email: invitee_email} = invitee, invite_id) do
    invite =
      Invite.get(invite_id)
      |> Invite.with_time_limit()
      |> Invite.with_organisation()
      |> Repo.one()

    with %Invite{email: ^invitee_email} <- invite,
         {:ok, :no_member} <- check_membership(invitee, invite.organisation_id) do
      convert_to_membership(invitee, invite)
    else
      {:ok, :is_member} -> {:error, :already_member}
      nil -> {:error, :invalid_invite}
    end
  end

  def delete_invite(invite_id) do
    case Invite.get(invite_id)
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

  # internal

  defp convert_to_membership(
         %User{} = user,
         %Invite{} = invite
       ) do
    Repo.transaction(fn ->
      membership =
        %Membership{user: user, organisation: invite.organisation, role: :viewer}
        |> Repo.insert!()

      Repo.delete(invite)
      membership
    end)
  end

  defp check_membership(%User{id: user_id}, org_id) do
    memberships =
      Membership.for_user(user_id)
      |> Repo.all()

    if Enum.any?(memberships, fn m -> m.organisation_id == org_id end) do
      {:ok, :is_member}
    else
      {:ok, :no_member}
    end
  end

  defp assert_not_last_member(
         %Organisation{} = organisation,
         %Membership{}
       ) do
    if organisation.memberships |> Enum.count() > 1 do
      :ok
    else
      {:error, :last_member}
    end
  end

  defp assert_not_last_owner(
         %Organisation{} = organisation,
         %Membership{role: :owner}
       ) do
    owner_count =
      organisation.memberships
      |> Enum.filter(fn m -> m.role == :owner end)
      |> Enum.count()

    if owner_count <= 1 do
      {:error, :last_owner}
    else
      :ok
    end
  end

  defp assert_not_last_owner(_organisation, %Membership{role: _non_owner_role}), do: :ok
end
