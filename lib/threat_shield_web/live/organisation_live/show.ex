defmodule ThreatShieldWeb.OrganisationLive.Show do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Organsations

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:organisation, Organsations.get_organisation!(id))}
  end

  defp page_title(:show), do: "Show Organisation"
  defp page_title(:edit), do: "Edit Organisation"
end
