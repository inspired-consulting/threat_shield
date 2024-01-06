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

  def list_organisations(%User{} = user) do
    full_user =
      Repo.get(User, user.id)
      |> Repo.preload(:organisations)

    full_user.organisations
  end

  def list_organisations(_), do: []

  def get_organisation!(%User{id: user_id}, org_id) do
    Organisation.get(org_id)
    |> Organisation.for_user(user_id)
    |> Organisation.preload_membership()
    |> Organisation.with_systems()
    |> Organisation.with_threats()
    |> Organisation.with_assets()
    |> Repo.one!()
  end

  def get_organisation_for_dashboard!(%User{id: user_id}, org_id) do
    Organisation.get(org_id)
    |> Organisation.for_user(user_id)
    |> Organisation.with_threats()
    |> Organisation.with_risks()
    |> Organisation.with_mitigations()
    |> Organisation.preload_membership()
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
    case Repo.transaction(fn ->
           case %Organisation{}
                |> Organisation.changeset(attrs)
                |> Repo.insert() do
             {:ok, org} ->
               %Membership{organisation: org, user: current_user, role: :owner}
               |> Membership.changeset(%{})
               |> Repo.insert()

               {:ok, org}

             x ->
               x
           end
         end) do
      {:ok, {:ok, org}} -> {:ok, org}
      {:ok, {:error, e}} -> {:error, e}
      {:error, e} -> e
    end
  end

  def update_organisation(
        %Organisation{id: org_id},
        %User{id: user_id},
        attrs
      ) do
    Repo.transaction(fn ->
      Organisation.get(org_id)
      |> Organisation.for_user(user_id, :edit_organisation)
      |> Repo.one!()
      |> Organisation.changeset(attrs)
      |> Repo.update!()
    end)
  end

  def delete_organisation(%Organisation{} = organisation) do
    Repo.delete(organisation)
  end

  def change_organisation(%Organisation{} = organisation, attrs \\ %{}) do
    Organisation.changeset(organisation, attrs)
  end

  def delete_org_by_id!(%User{id: user_id}, id) do
    Organisation.get(id)
    |> Organisation.for_user(user_id, :delete_organisation)
    |> Organisation.select()
    |> Repo.delete_all()
  end
end
