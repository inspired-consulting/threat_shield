defmodule ThreatShield.Assets do
  @moduledoc """
  The Assets context.
  """

  import Ecto.Query, warn: false
  alias ThreatShield.Repo

  alias Ecto.Multi

  alias ThreatShield.Assets.Asset
  alias ThreatShield.Accounts.User
  alias ThreatShield.Systems.System
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
    IO.inspect(attrs)

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
    attrs |> IO.inspect()

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

  def add_asset_by_id(%User{id: user_id}, asset_id) do
    Repo.transaction(fn ->
      Asset.get(asset_id)
      |> Asset.for_user(user_id)
      |> Repo.one!()
      |> Repo.preload([:organisation, :system])
      |> Asset.changeset(%{is_candidate: false})
      |> Repo.update!()
    end)
  end

  def bulk_add_asset_candidates(%User{} = user, %Organisation{} = organisation, assets) do
    multi =
      Multi.new()
      |> Multi.exists?(:check_access, Organisations.is_member_query(user, organisation))

    {:ok, result} =
      Enum.reduce(
        assets,
        multi,
        fn asset, acc ->
          Multi.insert(
            acc,
            {:insert_asset, asset.description},
            asset
            |> Ecto.Changeset.change()
            |> Ecto.Changeset.put_assoc(:organisation, organisation)
          )
        end
      )
      |> Repo.transaction()

    result
    |> Enum.filter(fn {k, _v} ->
      case k do
        {:insert_asset, _} -> true
        _ -> false
      end
    end)
    |> Enum.map(fn {_k, v} -> v end)
  end

  defp get_single_asset_query(user, asset_id) do
    Asset.get(asset_id)
    |> Asset.for_user(user.id)
  end
end
