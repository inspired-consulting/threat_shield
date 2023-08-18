defmodule ThreatShieldWeb.RiskLive.Show do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Risks

  @impl true
  def mount(%{"org_id" => org_id, "threat_id" => threat_id}, _session, socket) do
    user = socket.assigns.current_user
    threat = Risks.get_threat!(user, org_id, threat_id)

    {:ok,
     socket
     |> assign(threat: threat)
     |> assign(organisation: threat.organisation)}
  end

  @impl true
  def handle_params(%{"risk_id" => id}, _, socket) do
    user = socket.assigns.current_user

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:risk, Risks.get_risk!(user, id))}
  end

  defp page_title(:show), do: "Show Risk"
  defp page_title(:edit), do: "Edit Risk"
end
