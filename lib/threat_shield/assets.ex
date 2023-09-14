defmodule ThreatShield.Assets do
  @moduledoc """
  The Assets context.
  """

  import Ecto.Query, warn: false
  alias ThreatShield.Repo

  alias ThreatShield.Assets.Asset
  alias ThreatShield.Accounts.User
  alias ThreatShield.Systems.System
  alias ThreatShield.Systems
  alias ThreatShield.Organisations
  alias ThreatShield.Organisations.Organisation

  def get_organisation!(%User{id: user_id}, org_id) do
    Organisation.get(org_id)
    |> Organisation.for_user(user_id)
    |> Organisation.with_systems()
    |> Organisation.with_threats()
    |> Organisation.with_assets()
    |> Repo.one!()
  end

  def get_asset!(%User{id: user_id}, asset_id) do
    Asset.get(asset_id)
    |> Asset.for_user(user_id)
    |> Asset.preload_organisation()
    |> Asset.with_org_systems()
    |> Asset.with_system()
    |> Repo.one!()
  end

  def create_asset(%User{} = user, %Organisation{} = organisation, attrs \\ %{}) do
    changeset =
      %Asset{organisation: organisation}
      |> Asset.changeset(attrs)

    Repo.transaction(fn ->
      check_related_system_in_asset_changeset(changeset, user)
      Repo.one!(Organisations.is_member_query(user, organisation))

      Repo.insert!(changeset)
      |> Repo.reload!()
      |> Repo.preload(:system)
    end)
  end

  def update_asset(%User{} = user, %Asset{} = asset, attrs) do
    changeset =
      asset
      |> Asset.changeset(attrs)

    Repo.transaction(fn ->
      check_related_system_in_asset_changeset(changeset, user)
      Repo.one!(get_single_asset_query(user, asset.id))

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

  def delete_asset(%User{} = user, %Asset{} = asset) do
    Repo.transaction(fn ->
      Repo.one!(get_single_asset_query(user, asset.id))
      Repo.delete!(asset)
    end)
  end

  def change_asset(%Asset{} = asset, attrs \\ %{}) do
    Asset.changeset(asset, attrs)
  end

  def add_asset_with_description(%User{} = user, %System{id: sys_id}, description) do
    Repo.transaction(fn ->
      system = Systems.get_system!(user, sys_id)

      changeset =
        %Asset{organisation: system.organisation, system: system, description: description}
        |> Ecto.Changeset.change()

      Repo.insert!(changeset)
    end)
  end

  def add_asset_with_description(%User{} = user, org_id, description) do
    Repo.transaction(fn ->
      organisation = Organisations.get_organisation!(user, org_id)

      changeset =
        %Asset{organisation: organisation, description: description}
        |> Ecto.Changeset.change()

      Repo.insert!(changeset)
    end)
  end

  defp get_single_asset_query(user, asset_id) do
    Asset.get(asset_id)
    |> Asset.for_user(user.id)
  end
end
