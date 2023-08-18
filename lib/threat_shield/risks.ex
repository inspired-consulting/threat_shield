defmodule ThreatShield.Risks do
  @moduledoc """
  The Risks context.
  """

  import Ecto.Query, warn: false
  alias ThreatShield.Repo
  alias ThreatShield.Accounts.User

  alias ThreatShield.Risks.Risk
  alias ThreatShield.Threats.Threat

  def get_risk!(%User{id: user_id}, risk_id) do
    Risk.get(risk_id)
    |> Risk.for_user(user_id)
    |> Repo.one!()
  end

  def get_threat!(%User{id: user_id}, org_id, threat_id) do
    Threat.get(threat_id)
    |> Threat.for_user(user_id)
    |> Threat.where_organisation(org_id)
    |> Threat.with_organisation_and_risks()
    |> Repo.one!()
  end

  @doc """
  Creates a risk.

  ## Examples

      iex> create_risk(%{field: value})
      {:ok, %Risk{}}

      iex> create_risk(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_risk(attrs \\ %{}) do
    %Risk{}
    |> Risk.changeset(attrs)
    |> Repo.insert()
  end

  def update_risk(%User{id: user_id}, %Risk{id: risk_id} = risk, attrs) do
    Repo.transaction(fn ->
      Risk.get(risk_id)
      |> Risk.for_user(user_id)
      |> Repo.one!()

      risk
      |> Risk.changeset(attrs)
      |> Repo.update()
    end)
  end

  def delete_risk_by_id!(%User{id: user_id}, id) do
    Risk.get(id)
    |> Risk.for_user(user_id)
    |> Risk.select()
    |> Repo.delete_all()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking risk changes.

  ## Examples

      iex> change_risk(risk)
      %Ecto.Changeset{data: %Risk{}}

  """
  def change_risk(%Risk{} = risk, attrs \\ %{}) do
    Risk.changeset(risk, attrs)
  end
end
