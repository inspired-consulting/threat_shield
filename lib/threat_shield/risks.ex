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
    |> Risk.preload_threat()
    |> Risk.with_organisation()
    |> Risk.with_org_systems()
    |> Risk.with_mitigations()
    |> Repo.one!()
  end

  def get_threat!(%User{id: user_id}, org_id, threat_id) do
    Threat.get(threat_id)
    |> Threat.for_user(user_id)
    |> Threat.where_organisation(org_id)
    |> Threat.with_organisation_and_risks()
    |> Repo.one!()
  end

  def create_risk(%User{id: user_id}, threat_id, attrs \\ %{}) do
    Repo.transaction(fn ->
      threat =
        Threat.get(threat_id)
        |> Threat.for_user(user_id)
        |> Repo.one!()

      %Risk{}
      |> Risk.changeset(attrs)
      |> Ecto.Changeset.put_assoc(:threat, threat)
      |> Repo.insert!()
    end)
  end

  def update_risk(%User{id: user_id}, %Risk{id: risk_id} = risk, attrs) do
    Repo.transaction(fn ->
      Risk.get(risk_id)
      |> Risk.for_user(user_id)
      |> Repo.one!()

      risk
      |> Risk.changeset(attrs)
      |> Repo.update!()
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

  def add_risk(%User{id: user_id}, threat_id, name, description) do
    Repo.transaction(fn ->
      threat =
        Threat.get(threat_id)
        |> Threat.for_user(user_id)
        |> Repo.one!()

      %Risk{name: name, description: description}
      |> change_risk()
      |> Ecto.Changeset.put_assoc(:threat, threat)
      |> Repo.insert!()
    end)
  end
end
