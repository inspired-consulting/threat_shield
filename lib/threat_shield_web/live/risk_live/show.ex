defmodule ThreatShieldWeb.RiskLive.Show do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Risks

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"threat_id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:risk, Risks.get_risk!(id))}
  end

  defp page_title(:show), do: "Show Risk"
  defp page_title(:edit), do: "Edit Risk"
end
