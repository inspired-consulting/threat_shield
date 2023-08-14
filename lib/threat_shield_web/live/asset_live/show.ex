defmodule ThreatShieldWeb.AssetLive.Show do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Assets

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    organisation = Organisations.get_organisation_for_user!(org_id, current_user)

    socket =
      socket
      |> assign(:organisation, organisation)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"asset_id" => id}, _, socket) do
    user =
      socket.assigns.current_user

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:asset, Assets.get_asset!(id))}
  end

  defp page_title(:show), do: "Show Asset"
  defp page_title(:edit), do: "Edit Asset"
end
