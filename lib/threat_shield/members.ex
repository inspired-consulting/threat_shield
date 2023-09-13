defmodule ThreatShield.Members do
  @moduledoc """
  The Members context.
  """

  import Ecto.Query, warn: false
  alias ThreatShield.Organisations.Organisation
  alias ThreatShield.Repo

  alias ThreatShield.Members.Invite
  alias ThreatShield.Members
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

  @doc """
  Gets a single invite.

  Raises `Ecto.NoResultsError` if the Invites does not exist.

  ## Examples

      iex> get_invite!(123)
      %Invites{}

      iex> get_invite!(456)
      ** (Ecto.NoResultsError)

  """
  def get_invite!(id), do: Repo.get!(Invites, id)

  @doc """
  Creates a invite.

  ## Examples

      iex> create_invite(%{field: value})
      {:ok, %Invites{}}

      iex> create_invite(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
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

  @doc """
  Updates a invite.

  ## Examples

      iex> update_invite(invite, %{field: new_value})
      {:ok, %Invites{}}

      iex> update_invite(invite, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_invite(%Invite{} = invite, attrs) do
    invite
    |> Invite.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a invite.

  ## Examples

      iex> delete_invite(invite)
      {:ok, %Invites{}}

      iex> delete_invite(invite)
      {:error, %Ecto.Changeset{}}

  """
  def delete_invite(%Invite{} = invite) do
    Repo.delete(invite)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking invite changes.

  ## Examples

      iex> change_invite(invite)
      %Ecto.Changeset{data: %Invites{}}

  """
  def change_invite(%Invite{} = invite, attrs \\ %{}) do
    Invite.changeset(invite, attrs)
  end
end
