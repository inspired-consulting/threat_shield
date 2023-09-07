defmodule ThreatShield.Organisations do
  @moduledoc """
  The Organisations context.
  """

  import Ecto.Query, warn: false
  alias ThreatShield.Repo

  alias ThreatShield.Organisations.Organisation
  alias ThreatShield.Organisations.Membership
  alias ThreatShield.Accounts.User

  @doc """
  Returns the list of organisations.

  ## Examples

      iex> list_organisations(user)
      [%Organisation{}, %Organisation{}]

  """

  def list_organisations(user) do
    full_user =
      Repo.get(User, user.id)
      |> Repo.preload(:organisations)

    full_user.organisations
  end

  def get_organisation!(%User{id: user_id}, org_id) do
    Organisation.get(org_id)
    |> Organisation.for_user(user_id)
    |> Repo.one!()
  end

  def get_organisation_for_dashboard!(%User{id: user_id}, org_id) do
    Organisation.get(org_id)
    |> Organisation.for_user(user_id)
    |> Organisation.with_threats()
    |> Organisation.with_risks()
    |> Repo.one!()
  end

  def get_first_organisation_if_existent(user) do
    first_org =
      case list_organisations(user) do
        [first | _] -> first
        _ -> nil
      end

    case first_org do
      nil -> {:error, nil}
      org -> {:ok, get_organisation_for_dashboard!(user, org.id)}
    end
  end

  def create_organisation(attrs \\ %{}, %User{} = current_user) do
    %Organisation{}
    |> Organisation.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:users, [current_user])
    |> Repo.insert()
  end

  def update_organisation(%Organisation{} = organisation, %User{} = user, attrs) do
    changeset =
      organisation
      |> Organisation.changeset(attrs)

    Repo.transaction(fn ->
      Repo.one!(is_member_query(user, organisation))
      Repo.update!(changeset)
    end)
  end

  def delete_organisation(%Organisation{} = organisation) do
    Repo.delete(organisation)
  end

  def change_organisation(%Organisation{} = organisation, attrs \\ %{}) do
    Organisation.changeset(organisation, attrs)
  end

  def is_member_query(user, organisation) do
    from m in Membership,
      where: m.organisation_id == ^organisation.id and m.user_id == ^user.id
  end
end
