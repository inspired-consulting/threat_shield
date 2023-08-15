defmodule ThreatShieldWeb.AssetLive.Show do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Assets

  import ThreatShield.Assets.Asset, only: [list_system_options: 1, system_name: 1]

  @impl true
  def mount(%{"org_id" => org_id}, _session, socket) do
    current_user = socket.assigns.current_user
    organisation = Assets.get_organisation!(current_user, org_id)

    socket =
      socket
      |> assign(:organisation, organisation)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"asset_id" => asset_id}, _, socket) do
    user =
      socket.assigns.current_user

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:asset, Assets.get_asset!(user, asset_id))}
  end

  defp page_title(:show), do: "Show Asset"
  defp page_title(:edit), do: "Edit Asset"
end
