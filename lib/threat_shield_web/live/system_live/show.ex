defmodule ThreatShieldWeb.SystemLive.Show do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Systems

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"sys_id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:system, Systems.get_system!(id))}
  end

  defp page_title(:show), do: "Show System"
  defp page_title(:edit), do: "Edit System"
end
