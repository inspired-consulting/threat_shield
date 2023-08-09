defmodule ThreatShield.Systems do
  @moduledoc """
  The Systems context.
  """

  import Ecto.Query, warn: false
  alias ThreatShield.Repo

  alias ThreatShield.Accounts.User
  alias ThreatShield.Systems.System
  alias ThreatShield.Organisations
  alias ThreatShield.Organisations.Membership

  @doc """
  Returns the list of systems.

  ## Examples

      iex> list_systems()
      [%System{}, ...]

  """
  def list_systems_for_user_and_org(user, org_id) do
    Repo.get_by(Membership, user_id: user.id, organisation_id: org_id)
    |> Repo.preload(organisation: [:systems])
  end

  @doc """
  Gets a single system.

  Raises `Ecto.NoResultsError` if the System does not exist.

  ## Examples

      iex> get_system!(123)
      %System{}

      iex> get_system!(456)
      ** (Ecto.NoResultsError)

  """
  def get_system!(id), do: Repo.get!(System, id)

  def get_system_for_user_and_org(%User{} = user, org_id, sys_id) do
    query =
      from m in Membership,
        where: m.user_id == ^user.id and m.organisation_id == ^org_id,
        join: o in assoc(m, :organisation),
        join: s in assoc(o, :systems),
        where: s.id == ^sys_id,
        select: s

    Repo.one!(query)
    |> Repo.preload(:organisation)
  end

  @doc """
  Creates a system.

  ## Examples

      iex> create_system(%{field: value})
      {:ok, %System{}}

      iex> create_system(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_system(user, organisation, attrs \\ %{}) do
    changeset =
      %System{}
      |> System.changeset(attrs)
      |> Ecto.Changeset.put_assoc(:organisation, organisation)

    Repo.transaction(fn ->
      Repo.one!(Organisations.is_member_query(user, organisation))
      Repo.insert!(changeset)
    end)
  end

  @doc """
  Updates a system.

  ## Examples

      iex> update_system(system, %{field: new_value})
      {:ok, %System{}}

      iex> update_system(system, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_system(user, organisation, %System{} = system, attrs) do
    changeset =
      system
      |> System.changeset(attrs)

    Repo.transaction(fn ->
      Repo.one!(Organisations.is_member_query(user, organisation))
      Repo.update!(changeset)
    end)
  end

  @doc """
  Deletes a system.

  ## Examples

      iex> delete_system(system)
      {:ok, %System{}}

      iex> delete_system(system)
      {:error, %Ecto.Changeset{}}

  """
  def delete_system(user, organisation, %System{} = system) do
    Repo.transaction(fn ->
      Repo.one!(Organisations.is_member_query(user, organisation))
      Repo.delete(system)
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking system changes.

  ## Examples

      iex> change_system(system)
      %Ecto.Changeset{data: %System{}}

  """
  def change_system(%System{} = system, attrs \\ %{}) do
    System.changeset(system, attrs)
  end
end
