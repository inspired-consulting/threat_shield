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
    |> Repo.preload(assets: [:system])
    |> Repo.preload(:systems)
  end

  def get_asset!(%User{id: user_id}, asset_id) do
    Asset.get(asset_id)
    |> Asset.for_user(user_id)
    |> Repo.one!()
    |> Repo.preload([:organisation, :system])
  end

  def create_asset(%User{} = user, %Organisation{} = organisation, attrs \\ %{}) do
    changeset =
      %Asset{organisation: organisation}
      |> Asset.changeset(attrs)

    Repo.transaction(fn ->
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
      Repo.one!(get_single_asset_query(user, asset.id))

      Repo.update!(changeset)
      |> Repo.reload!()
      |> Repo.preload(:system)
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

  def add_asset_by_id(user, id), do: update_is_candidate_for_id(user, id, false)

  def ignore_asset_by_id(user, id), do: update_is_candidate_for_id(user, id, true)

  defp update_is_candidate_for_id(%User{id: user_id}, asset_id, target_value) do
    Repo.transaction(fn ->
      Asset.get(asset_id)
      |> Asset.for_user(user_id)
      |> Repo.one!()
      |> Repo.preload([:organisation, :system])
      |> Asset.changeset(%{is_candidate: target_value})
      |> Repo.update!()
    end)
  end

  defp get_single_asset_query(user, asset_id) do
    Asset.get(asset_id)
    |> Asset.for_user(user.id)
  end
end
