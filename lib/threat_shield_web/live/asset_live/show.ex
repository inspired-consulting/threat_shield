defmodule ThreatShieldWeb.AssetLive.Show do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Assets
  alias ThreatShield.Organisations.Organisation

  import ThreatShield.Organisations.Organisation,
    only: [list_system_options: 1]

  import ThreatShieldWeb.Helpers, only: [add_breadcrumbs: 2, get_path_prefix: 1]

  import ThreatShieldWeb.Labels, only: [system_label: 1]

  @impl true
  def mount(%{"asset_id" => asset_id} = params, _session, socket) do
    current_user = socket.assigns.current_user
    asset = Assets.get_asset!(current_user, asset_id)

    socket =
      socket
      |> assign(:asset, asset)
      |> assign(:organisation, asset.organisation)
      |> assign(
        :membership,
        Organisation.get_membership(asset.organisation, current_user)
      )
      |> assign(:system, asset.system)
      |> assign(:called_via_system, Map.has_key?(params, "sys_id"))

    socket_with_options =
      if socket.assigns.called_via_system do
        socket
      else
        assign(socket, :system_options, list_system_options(asset.organisation))
      end

    {:ok, socket_with_options}
  end

  @impl true
  def handle_params(_params, url, socket) do
    {:noreply,
     socket
     |> add_breadcrumbs(url)
     |> assign(:page_title, page_title(socket.assigns.live_action))}
  end

  @impl true
  def handle_event("delete", %{"asset_id" => asset_id}, socket) do
    user = socket.assigns.current_user
    {1, [_asset]} = Assets.delete_asset_by_id(user, asset_id)

    {:noreply, push_navigate(socket, to: get_path_prefix(socket.assigns))}
  end

  @impl true
  def handle_info(
        {ThreatShieldWeb.AssetLive.AssetForm, {:saved, asset}},
        socket
      ) do
    asset = Assets.get_asset!(socket.assigns.current_user, asset.id)

    {:noreply,
     socket
     |> assign(asset: asset)
     |> assign(organisation: asset.organisation)
     |> assign(:system, asset.system)
     |> assign(page_title: "Show Asset")}
  end

  defp page_title(:show), do: "Show Asset"
  defp page_title(:edit), do: "Edit Asset"
end
