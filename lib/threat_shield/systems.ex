defmodule ThreatShield.Systems do
  @moduledoc """
  The Systems context.
  """

  import Ecto.Query, warn: false
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

  def delete_sys_by_id!(%User{id: user_id}, id) do
    System.get(id)
    |> System.for_user(user_id)
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
