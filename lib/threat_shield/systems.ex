defmodule ThreatShield.Systems do
  @moduledoc """
  The Systems context.
  """

  import Ecto.Query, warn: false
  alias ThreatShield.Organisations.Organisation
  alias ThreatShield.Repo

  alias ThreatShield.Accounts.User
  alias ThreatShield.Systems.System
  alias ThreatShield.Organisations

  def get_organisation!(user, org_id) do
    Organisations.get_organisation!(user, org_id)
    |> Repo.preload(:systems)
  end

  def get_system!(%User{id: user_id}, sys_id) do
    System.get(sys_id)
    |> System.for_user(user_id)
    |> System.with_assets()
    |> System.with_threats()
    |> System.preload_organisation()
    |> System.with_org_systems()
    |> System.preload_membership()
    |> Repo.one!()
  end

  @doc """
  Creates a system.

  ## Examples

      iex> create_system(%{field: value})
      {:ok, %System{}}

      iex> create_system(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_system(%User{id: user_id}, %Organisation{id: org_id}, attrs \\ %{}) do
    Repo.transaction(fn ->
      organisation =
        Organisation.get(org_id)
        |> Organisation.for_user(user_id, :create_system)
        |> Repo.one!()

      %System{}
      |> System.changeset(attrs)
      |> Ecto.Changeset.put_assoc(:organisation, organisation)
      |> Repo.insert!()
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
  def update_system(%User{id: user_id}, %System{id: sys_id}, attrs) do
    System.get(sys_id)
    |> System.for_user(user_id, :edit_system)
    |> Repo.one!()
    |> System.changeset(attrs)
    |> Repo.update()
  end

  def delete_sys_by_id!(%User{id: user_id}, id) do
    System.get(id)
    |> System.for_user(user_id, :delete_system)
    |> System.select()
    |> Repo.delete_all()
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
