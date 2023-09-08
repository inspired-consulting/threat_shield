defmodule ThreatShield.Mitigations do
  @moduledoc """
  The Mitigations context.
  """

  import Ecto.Query, warn: false
  alias ThreatShield.Accounts.User
  alias ThreatShield.Risks.Risk
  alias ThreatShield.Repo

  alias ThreatShield.Mitigations.Mitigation

  def get_risk!(%User{id: user_id}, risk_id) do
    Risk.get(risk_id)
    |> Risk.for_user(user_id)
    |> Risk.with_mitigations()
    |> Risk.with_organisation()
    |> Repo.one!()
  end

  @doc """
  Returns the list of mitigations.

  ## Examples

      iex> list_mitigations()
      [%Mitigation{}, ...]

  """
  def list_mitigations do
    Repo.all(Mitigation)
  end

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
    |> Repo.one!()
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
    Repo.transaction(fn ->
      risk =
        Risk.get(risk_id)
        |> Risk.for_user(user_id)
        |> Repo.one!()

      %Mitigation{}
      |> Mitigation.changeset(attrs)
      |> Ecto.Changeset.put_assoc(:risk, risk)
      |> Repo.insert!()
    end)
  end

  @doc """
  Updates a mitigation.

  ## Examples

      iex> update_mitigation(mitigation, %{field: new_value})
      {:ok, %Mitigation{}}

      iex> update_mitigation(mitigation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_mitigation(%Mitigation{} = mitigation, attrs) do
    mitigation
    |> Mitigation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a mitigation.

  ## Examples

      iex> delete_mitigation(mitigation)
      {:ok, %Mitigation{}}

      iex> delete_mitigation(mitigation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_mitigation(%Mitigation{} = mitigation) do
    Repo.delete(mitigation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking mitigation changes.

  ## Examples

      iex> change_mitigation(mitigation)
      %Ecto.Changeset{data: %Mitigation{}}

  """
  def change_mitigation(%Mitigation{} = mitigation, attrs \\ %{}) do
    Mitigation.changeset(mitigation, attrs)
  end

  def delete_mitigation_by_id!(%User{id: user_id}, id) do
    Mitigation.get(id)
    |> Mitigation.for_user(user_id)
    |> Mitigation.select()
    |> Repo.delete_all()
  end
end
