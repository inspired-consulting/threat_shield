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
  alias ThreatShield.Accounts.Organisation

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

  def list_assets(%User{id: user_id}, %Organisation{id: org_id}) do
    Asset.from()
    |> Asset.for_user(user_id)
    |> Asset.for_organisation(org_id)
    |> Asset.with_threats()
    |> Repo.all()
  end

  def find_by_system(%User{id: user_id}, %System{id: system_id, organisation_id: org_id}) do
    Asset.from()
    |> Asset.for_user(user_id)
    |> Asset.for_organisation(org_id)
    |> Asset.where_system(system_id)
    |> Asset.with_threats()
    |> Repo.all()
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

  @doc """
  Creates an asset with the given name and description for the scope: for its
  organisation and, if the scope has one, for its system.
  """
  def add_asset_with_name_and_description(%Scope{} = scope, name, description) do
    create_asset(scope.user, scope.organisation, %{
      name: name,
      description: description,
      system_id: scope.system && scope.system.id
    })
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
