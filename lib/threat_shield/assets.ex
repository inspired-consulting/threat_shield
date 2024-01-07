defmodule ThreatShield.Assets do
  @moduledoc """
  The Assets context.
  """

  import Ecto.Query, warn: false
  alias ThreatShield.Repo
  alias ThreatShield.Scope

  alias ThreatShield.Assets.Asset
  alias ThreatShield.Accounts.User
  alias ThreatShield.Systems.System
  alias ThreatShield.Organisations.Organisation

  def get_organisation!(%User{id: user_id}, org_id) do
    Organisation.get(org_id)
    |> Organisation.for_user(user_id)
    |> Organisation.with_systems()
    |> Organisation.with_threats()
    |> Organisation.with_assets()
    |> Repo.one!()
  end

  def count_all_assets() do
    Asset
    |> Repo.aggregate(:count, :id)
  end

  def get_asset!(%User{id: user_id}, asset_id) do
    Asset.get(asset_id)
    |> Asset.for_user(user_id)
    |> Asset.preload_organisation()
    |> Asset.with_system()
    |> Asset.with_threats()
    |> Asset.with_org_systems()
    |> Asset.with_org_assets()
    |> Asset.preload_membership()
    |> Repo.one!()
  end

  def prepare_asset(system_id \\ nil) do
    %Asset{
      system_id: system_id,
      criticality_loss: 0.0,
      criticality_theft: 0.0,
      criticality_publication: 0.0,
      criticality_overall: 0.0
    }
  end

  def change_asset(%Asset{} = asset, attrs \\ %{}) do
    Asset.changeset(asset, attrs)
    |> update_overall_criticality()
  end

  def create_asset(
        %User{id: user_id} = user,
        %Organisation{id: org_id} = organisation,
        attrs \\ %{}
      ) do
    changeset =
      %Asset{organisation: organisation}
      |> Asset.changeset(attrs)

    Repo.transaction(fn ->
      check_related_system_in_asset_changeset(changeset, user)

      Organisation.get(org_id)
      |> Organisation.for_user(user_id, :create_asset)
      |> Repo.one!()

      Repo.insert!(changeset)
      |> Repo.reload!()
      |> Repo.preload(:system)
    end)
  end

  def update_asset(%User{id: user_id} = user, %Asset{id: asset_id} = asset, attrs) do
    changeset =
      asset
      |> Asset.changeset(attrs)

    Repo.transaction(fn ->
      check_related_system_in_asset_changeset(changeset, user)

      Asset.get(asset_id)
      |> Asset.for_user(user_id, :edit_asset)
      |> Repo.one!()

      Repo.update!(changeset)
      |> Repo.reload!()
      |> Repo.preload(:system)
    end)
  end

  defp check_related_system_in_asset_changeset(%{changes: %{system_id: sys_id}}, user)
       when not is_nil(sys_id) do
    System.get(sys_id)
    |> System.for_user(user.id)
    |> Repo.one!()
  end

  defp check_related_system_in_asset_changeset(_, _user) do
  end

  def add_asset_with_name_and_description(
        %Scope{} = scope,
        name,
        description
      ) do
    case scope do
      %Scope{system: %System{} = system} ->
        add_asset_with_name_and_description(scope.user, system, name, description)

      %Scope{organisation: %Organisation{} = organisation} ->
        add_asset_with_name_and_description(scope.user, organisation, name, description)
    end
  end

  def add_asset_with_name_and_description(
        %User{id: user_id},
        %System{id: sys_id},
        name,
        description
      ) do
    Repo.transaction(fn ->
      system =
        System.get(sys_id)
        |> System.for_user(user_id, :create_asset)
        |> System.preload_organisation()
        |> Repo.one!()

      changeset =
        %Asset{
          organisation: system.organisation,
          system: system,
          name: name,
          description: description
        }
        |> Ecto.Changeset.change()

      Repo.insert!(changeset)
    end)
  end

  def add_asset_with_name_and_description(
        %User{id: user_id},
        %Organisation{id: org_id},
        name,
        description
      ) do
    Repo.transaction(fn ->
      organisation =
        Organisation.get(org_id)
        |> Organisation.for_user(user_id, :create_asset)
        |> Repo.one!()

      changeset =
        %Asset{organisation: organisation, description: description, name: name}
        |> Ecto.Changeset.change()

      Repo.insert!(changeset)
    end)
  end

  defp update_overall_criticality(%Ecto.Changeset{} = asset_cs) do
    asset = Ecto.Changeset.apply_changes(asset_cs)
    crit = Asset.calc_overall_criticality(asset)

    asset_cs
    |> Ecto.Changeset.put_change(:criticality_overall, crit)
  end

  def delete_asset_by_id(%User{id: user_id}, asset_id) do
    Asset.get(asset_id)
    |> Asset.for_user(user_id, :delete_asset)
    |> Asset.select()
    |> Repo.delete_all()
  end
end
