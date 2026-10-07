defmodule ThreatShield.Threats do
  @moduledoc """
  The Threats context.
  """

  import Ecto.Query, warn: false

  alias ThreatShield.Repo
  alias ThreatShield.Scope

  alias ThreatShield.Threats.Threat
  alias ThreatShield.Accounts.User
  alias ThreatShield.Accounts.Organisation
  alias ThreatShield.Systems.System
  alias ThreatShield.Assets.Asset

  def get_threat!(%User{id: user_id}, threat_id) do
    Threat.get(threat_id)
    |> Threat.for_user(user_id)
    |> Threat.with_system()
    |> Threat.with_asset()
    |> Threat.with_organisation_and_risks()
    |> Threat.with_org_systems()
    |> Threat.with_org_assets()
    |> Threat.preload_membership()
    |> Repo.one!()
  end

  def list_threats(%User{id: user_id}, %Organisation{id: org_id}) do
    Threat.from()
    |> Threat.for_user(user_id)
    |> Threat.for_organisation(org_id)
    |> Threat.with_system()
    |> Threat.with_asset()
    |> Threat.with_organisation_and_risks()
    |> Threat.with_org_systems()
    |> Threat.with_org_assets()
    |> Repo.all()
  end

  def find_by_system(%User{id: user_id}, %System{id: system_id, organisation_id: org_id}) do
    Threat.from()
    |> Threat.for_user(user_id)
    |> Threat.where_organisation(org_id)
    |> Threat.where_system(system_id)
    |> Threat.with_system()
    |> Threat.with_asset()
    |> Repo.all()
  end

  def find_by_asset(%Asset{id: asset_id, organisation_id: org_id}) do
    Threat.from()
    |> Threat.where_organisation(org_id)
    |> Threat.where_asset(asset_id)
    |> Threat.with_system()
    |> Threat.with_asset()
    |> Repo.all()
  end

  def count_all_threats(%Organisation{id: org_id}) do
    Threat.from()
    |> Threat.where_organisation(org_id)
    |> Repo.aggregate(:count, :id)
  end

  def create_threat(
        %User{id: user_id},
        %Organisation{id: org_id} = organisation,
        attrs \\ %{}
      ) do
    changeset =
      %Threat{organisation: organisation}
      |> Threat.changeset(attrs)

    Repo.transaction(fn ->
      Organisation.get(org_id)
      |> Organisation.for_user(user_id, :create_threat)
      |> Repo.one!()

      check_related_entities_in_threat_changeset(changeset, org_id)

      Repo.insert_or_rollback(changeset)
    end)
  end

  @doc """
  Creates a threat with the given name and description for the scope: for its
  organisation and, if the scope has them, for its system and its asset.
  """
  def add_threat_with_name_and_description(%Scope{} = scope, name, description) do
    create_threat(scope.user, scope.organisation, %{
      name: name,
      description: description,
      system_id: scope.system && scope.system.id,
      asset_id: scope.asset && scope.asset.id
    })
  end

  def update_threat(%User{id: user_id}, %Threat{id: threat_id} = threat, attrs) do
    changeset =
      threat
      |> Threat.changeset(attrs)

    Repo.transaction(fn ->
      %Threat{organisation_id: org_id} =
        Threat.get(threat_id)
        |> Threat.for_user(user_id, :edit_threat)
        |> Repo.one!()

      check_related_entities_in_threat_changeset(changeset, org_id)

      Repo.update_or_rollback(changeset)
    end)
  end

  def delete_threat_by_id(%User{id: user_id}, threat_id) do
    case Threat.get(threat_id)
         |> Threat.for_user(user_id, :delete_threat)
         |> Threat.select()
         |> Repo.delete_all() do
      {1, _} -> {:ok, 1}
      _ -> {:error, :unauthorized}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking threat changes.

  ## Examples

      iex> change_threat(threat)
      %Ecto.Changeset{data: %Threat{}}

  """
  def change_threat(%Threat{} = threat, attrs \\ %{}) do
    Threat.changeset(threat, attrs)
  end

  # A threat may only reference a system and an asset of its own organisation.
  defp check_related_entities_in_threat_changeset(%Ecto.Changeset{changes: changes}, org_id) do
    case changes do
      %{system_id: sys_id} when not is_nil(sys_id) ->
        System.get(sys_id)
        |> System.for_organisation(org_id)
        |> Repo.one!()

      _ ->
        nil
    end

    case changes do
      %{asset_id: asset_id} when not is_nil(asset_id) ->
        Asset.get(asset_id)
        |> Asset.for_organisation(org_id)
        |> Repo.one!()

      _ ->
        nil
    end
  end
end
