defmodule ThreatShield.Threats do
  @moduledoc """
  The Threats context.
  """

  import Ecto.Query, warn: false

  alias ThreatShield.Repo
  alias ThreatShield.Scope

  alias ThreatShield.Threats.Threat
  alias ThreatShield.Accounts.User
  alias ThreatShield.Organisations
  alias ThreatShield.Accounts.Organisation
  alias ThreatShield.Systems.System
  alias ThreatShield.Assets.Asset

  def get_organisation!(%User{} = user, org_id) do
    Organisations.get_organisation!(user, org_id)
    |> Repo.preload(threats: :system)
    |> Repo.preload(:systems)
  end

  def count_all_threats() do
    Threat
    |> Repo.aggregate(:count, :id)
  end

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

  def count_threats_for_system(system_id) do
    Threat
    |> where([t], t.system_id == ^system_id)
    |> Repo.aggregate(:count, :id)
  end

  def create_threat(
        %User{id: user_id} = user,
        %Organisation{id: org_id} = organisation,
        attrs \\ %{}
      ) do
    changeset =
      %Threat{organisation: organisation}
      |> Threat.changeset(attrs)

    Repo.transaction(fn ->
      check_related_system_in_threat_changeset(changeset, user)

      Organisation.get(org_id)
      |> Organisation.for_user(user_id, :create_threat)
      |> Repo.one!()

      Repo.insert!(changeset)
    end)
  end

  def add_threat_with_name_and_description(
        %Scope{} = scope,
        name,
        description
      ) do
    case scope do
      %Scope{system: %System{} = system, asset: %Asset{} = asset} ->
        add_threat_with_name_and_description(scope.user, system, asset, name, description)

      %Scope{asset: %Asset{} = asset} ->
        add_threat_with_name_and_description(scope.user, asset, name, description)

      %Scope{system: %System{} = system} ->
        add_threat_with_name_and_description(scope.user, system, name, description)

      %Scope{organisation: %Organisation{} = organisation} ->
        add_threat_with_name_and_description(scope.user, organisation, name, description)
    end
  end

  def add_threat_with_name_and_description(
        %User{id: user_id},
        %System{id: sys_id},
        %Asset{id: asset_id},
        name,
        description
      ) do
    Repo.transaction(fn ->
      system =
        System.get(sys_id)
        |> System.for_user(user_id, :create_threat)
        |> System.preload_organisation()
        |> Repo.one!()

      asset =
        Asset.get(asset_id)
        |> Asset.for_user(user_id, :create_threat)
        |> Repo.one!()

      changeset =
        %Threat{
          system: system,
          asset: asset,
          organisation: system.organisation,
          name: name,
          description: description
        }
        |> Ecto.Changeset.change()

      Repo.insert!(changeset)
    end)
  end

  def add_threat_with_name_and_description(
        %User{id: user_id},
        %System{id: sys_id},
        name,
        description
      ) do
    Repo.transaction(fn ->
      system =
        System.get(sys_id)
        |> System.for_user(user_id, :create_threat)
        |> System.preload_organisation()
        |> Repo.one!()

      changeset =
        %Threat{
          system: system,
          organisation: system.organisation,
          name: name,
          description: description
        }
        |> Ecto.Changeset.change()

      Repo.insert!(changeset)
    end)
  end

  def add_threat_with_name_and_description(
        %User{id: user_id},
        %Asset{id: asset_id},
        name,
        description
      ) do
    Repo.transaction(fn ->
      asset =
        Asset.get(asset_id)
        |> Asset.for_user(user_id, :create_threat)
        |> Asset.preload_organisation()
        |> Repo.one!()

      changeset =
        %Threat{
          asset: asset,
          organisation: asset.organisation,
          name: name,
          description: description
        }
        |> Ecto.Changeset.change()

      Repo.insert!(changeset)
    end)
  end

  def add_threat_with_name_and_description(
        %User{id: user_id},
        %Organisation{id: org_id},
        name,
        description
      ) do
    Repo.transaction(fn ->
      organisation =
        Organisation.get(org_id)
        |> Organisation.for_user(user_id, :create_threat)
        |> Repo.one!()

      changeset =
        %Threat{organisation: organisation, description: description, name: name}
        |> Ecto.Changeset.change()

      Repo.insert!(changeset)
    end)
  end

  def update_threat(%User{id: user_id} = user, %Threat{id: threat_id} = threat, attrs) do
    changeset =
      threat
      |> Threat.changeset(attrs)

    Repo.transaction(fn ->
      check_related_system_in_threat_changeset(changeset, user)

      Threat.get(threat_id)
      |> Threat.for_user(user_id, :edit_threat)
      |> Repo.one!()

      Repo.update!(changeset)
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

  defp check_related_system_in_threat_changeset(%{changes: %{system_id: sys_id}}, user)
       when not is_nil(sys_id) do
    System.get(sys_id)
    |> System.for_user(user.id)
    |> Repo.one!()
  end

  defp check_related_system_in_threat_changeset(_, _user) do
  end
end
