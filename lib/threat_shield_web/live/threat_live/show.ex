defmodule ThreatShieldWeb.ThreatLive.Show do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Threats

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:threat, Threats.get_threat!(id))}
  end

  defp page_title(:show), do: "Show Threat"
  defp page_title(:edit), do: "Edit Threat"
end
