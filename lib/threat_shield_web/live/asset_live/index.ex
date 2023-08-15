defmodule ThreatShieldWeb.AssetLive.Index do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Assets
  alias ThreatShield.Organisations
  alias ThreatShield.Assets.Asset

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
    |> assign(:asset, Assets.get_asset!(id))
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
    asset = Assets.get_asset!(socket.assigns.current_user, asset_id)
    {:ok, _} = Assets.delete_asset(socket.assigns.current_user, asset)

    {:noreply, stream_delete(socket, :assets, asset)}
  end
end
