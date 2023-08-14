defmodule ThreatShieldWeb.AssetLive.Index do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Assets
  alias ThreatShield.Assets.Asset

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    organisation = Organisations.get_organisation_for_user!(org_id, current_user)
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
  def handle_event("delete", %{"asset_id" => id}, socket) do
    asset = Assets.get_asset!(id)
    {:ok, _} = Assets.delete_asset(asset)

    {:noreply, stream_delete(socket, :assets, asset)}
  end
end
