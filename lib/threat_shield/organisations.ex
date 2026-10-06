defmodule ThreatShield.Organisations do
  @moduledoc """
  The Organisations context.
  """

  import Ecto.Query, warn: false
  alias ThreatShield.Repo

  alias ThreatShield.Accounts.{User, Organisation, Membership, RBAC}

  @doc """
  Returns the list of organisations, where the user is a member of.

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

  @doc """
  Returns all organisaitions for given admin.
  """
  def list_all_organisations(%User{} = admin) do
    with :ok <- RBAC.verify_permission(admin, :administer_platform) do
      Repo.all(Organisation)
    else
      _ -> {:error, :not_allowed}
    end
  end

  def get_organisation!(%User{id: user_id}, org_id) do
    Organisation.get(org_id)
    |> Organisation.for_user(user_id)
    |> Organisation.preload_membership()
    |> Organisation.with_systems()
    |> Organisation.with_threats()
    |> Organisation.with_assets()
    |> Repo.one!()
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
