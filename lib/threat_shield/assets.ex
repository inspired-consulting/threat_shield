defmodule ThreatShield.Assets do
  @moduledoc """
  The Assets context.
  """

  import Ecto.Query, warn: false
  alias ThreatShield.Repo

  alias ThreatShield.Assets.Asset
  alias ThreatShield.Accounts.User
  alias ThreatShield.Organisations
  alias ThreatShield.Organisations.Organisation

  def get_organisation!(%User{} = user, org_id) do
    Organisations.get_organisation!(user, org_id)
    |> Repo.preload(:assets)
  end

  def get_asset!(%User{id: user_id}, asset_id) do
    Asset.get(asset_id)
    |> Asset.for_user(user_id)
    |> Repo.one!()
    |> Repo.preload(:organisation)
  end

  def create_asset(%User{} = user, %Organisation{} = organisation, attrs \\ %{}) do
    changeset =
      %Asset{organisation: organisation}
      |> Asset.changeset(attrs)

    Repo.transaction(fn ->
      Repo.one!(Organisations.is_member_query(user, organisation))
      Repo.insert!(changeset)
    end)
  end

  def update_asset(%User{} = user, %Asset{} = asset, attrs) do
    changeset =
      asset
      |> Asset.changeset(attrs)

    Repo.transaction(fn ->
      Repo.one!(get_single_asset_query(user, asset.id))
      Repo.update!(changeset)
    end)
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

  defp get_single_asset_query(user, asset_id) do
    Asset.get(asset_id)
    |> Asset.for_user(user.id)
  end
end
