defmodule ThreatShield.Mitigations do
  @moduledoc """
  The Mitigations context.
  """

  import Ecto.Query, warn: false
  alias ThreatShield.Accounts.{User, Organisation}
  alias ThreatShield.Risks.Risk
  alias ThreatShield.Repo

  alias ThreatShield.Mitigations.Mitigation

  @doc """
  Gets a single mitigation.

  Raises `Ecto.NoResultsError` if the Mitigation does not exist.

  ## Examples

      iex> get_mitigation!(123)
      %Mitigation{}

      iex> get_mitigation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_mitigation!(%User{id: user_id}, id) do
    Mitigation.get(id)
    |> Mitigation.for_user(user_id)
    |> Mitigation.preload_risk()
    |> Mitigation.preload_full_threat()
    |> Mitigation.preload_membership()
    |> Repo.one!()
  end

  def get_all_mitigations(%User{id: user_id}, org_id) do
    Mitigation.from()
    |> Mitigation.for_user(user_id)
    |> Mitigation.where_organisation(org_id)
    |> Mitigation.preload_risk()
    |> Repo.all()
  end

  def count_all_mitigations(%Organisation{id: org_id}) do
    Mitigation.from()
    |> Mitigation.where_organisation(org_id)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Creates a mitigation.

  ## Examples

      iex> create_mitigation(%{field: value})
      {:ok, %Mitigation{}}

      iex> create_mitigation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_mitigation(%User{id: user_id}, %Risk{id: risk_id}, attrs \\ %{}) do
    case Repo.transaction(fn ->
           risk =
             Risk.get(risk_id)
             |> Risk.for_user(user_id, :create_mitigation)
             |> Repo.one!()

           %Mitigation{}
           |> Mitigation.changeset(attrs)
           |> update_implementation_status()
           |> Ecto.Changeset.put_assoc(:risk, risk)
           |> Repo.insert()
         end) do
      {:ok, {:error, reason}} -> {:error, reason}
      {:ok, {:ok, payload}} -> {:ok, payload}
      {:error, rollback} -> {:error, rollback}
    end
  end

  @doc """
  Updates a mitigation.

  ## Examples

      iex> update_mitigation(mitigation, %{field: new_value})
      {:ok, %Mitigation{}}

      iex> update_mitigation(mitigation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_mitigation(%User{id: user_id}, %Mitigation{id: mitigation_id}, attrs) do
    Mitigation.get(mitigation_id)
    |> Mitigation.for_user(user_id, :edit_mitigation)
    |> Repo.one!()
    |> Mitigation.changeset(attrs)
    |> update_implementation_status()
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking mitigation changes.

  ## Examples

      iex> change_mitigation(mitigation)
      %Ecto.Changeset{data: %Mitigation{}}

  """
  def change_mitigation(%Mitigation{} = mitigation, attrs \\ %{}) do
    Mitigation.changeset(mitigation, attrs)
    |> update_implementation_status()
  end

  def delete_mitigation_by_id!(%User{id: user_id}, id) do
    Mitigation.get(id)
    |> Mitigation.for_user(user_id, :delete_mitigation)
    |> Mitigation.select()
    |> Repo.delete_all()
  end

  def add_mitigation(%User{id: user_id}, risk_id, name, description) do
    Repo.transaction(fn ->
      risk =
        Risk.get(risk_id)
        |> Risk.for_user(user_id, :create_mitigation)
        |> Repo.one!()

      %Mitigation{name: name, description: description}
      |> change_mitigation()
      |> Ecto.Changeset.put_assoc(:risk, risk)
      |> Repo.insert!()
    end)
  end

  # Internal

  defp update_implementation_status(%Ecto.Changeset{} = mitigation_cs) do
    %Mitigation{} = mitigation = Ecto.Changeset.apply_changes(mitigation_cs)

    implemented =
      case(to_string(mitigation.status)) do
        "implemented" ->
          true

        "verified" ->
          true

        _ ->
          false
      end

    mitigation_cs
    |> Ecto.Changeset.put_change(:is_implemented, implemented)
  end
end
