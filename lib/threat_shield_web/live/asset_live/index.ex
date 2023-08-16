defmodule ThreatShieldWeb.AssetLive.Index do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Assets
  alias ThreatShield.Assets.Asset
  alias ThreatShield.AI

  import ThreatShield.Assets.Asset,
    only: [system_name: 1]

  import ThreatShield.Organisations.Organisation,
    only: [list_system_options: 1]

  @impl true
  def mount(%{"org_id" => org_id}, _session, socket) do
    current_user = socket.assigns.current_user

    organisation = Assets.get_organisation!(current_user, org_id)
    assets = organisation.assets

    socket =
      socket
      |> assign(:organisation, organisation)

    {:ok, stream(socket, :assets, assets)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"asset_id" => id}) do
    socket
    |> assign(:page_title, "Edit Asset")
    |> assign(:asset, Assets.get_asset!(socket.assigns.current_user, id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Asset")
    |> assign(:asset, %Asset{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Assets")
    |> assign(:asset, nil)
  end

  @impl true
  def handle_info({ThreatShieldWeb.AssetLive.FormComponent, {:saved, asset}}, socket) do
    {:noreply, stream_insert(socket, :assets, asset)}
  end

  @impl true
  def handle_event("delete", %{"asset_id" => asset_id}, socket) do
    organisation = socket.assigns.organisation

    asset = Assets.get_asset!(socket.assigns.current_user, asset_id)
    {:ok, _} = Assets.delete_asset(socket.assigns.current_user, asset)

    {:noreply, push_navigate(socket, to: "/organisations/#{organisation.id}/assets")}
  end

  @impl true
  def handle_event("add", %{"asset_id" => id}, socket) do
    user = socket.assigns.current_user
    {:ok, asset} = Assets.add_asset_by_id(user, id)

    {:noreply, stream_insert(socket, :assets, asset)}
  end

  @impl true
  def handle_event("suggest", %{"org_id" => org_id}, socket) do
    user = socket.assigns.current_user

    organisation = Assets.get_organisation!(user, org_id)

    asset_descriptions =
      AI.suggest_assets_for_organisation(organisation)

    asset_candidates =
      Assets.bulk_add_asset_candidates(user, organisation, asset_descriptions)

    {:noreply, stream(socket, :assets, asset_candidates)}
  end
end
