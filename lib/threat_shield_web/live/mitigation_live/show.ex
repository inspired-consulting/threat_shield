defmodule ThreatShieldWeb.MitigationLive.Show do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Mitigations

  import ThreatShieldWeb.Helpers, only: [add_breadcrumbs: 2]

  @impl true
  def mount(%{"risk_id" => risk_id}, _session, socket) do
    user = socket.assigns.current_user
    risk = Mitigations.get_risk!(user, risk_id)

    {:ok,
     socket
     |> assign(risk: risk)
     |> assign(threat: risk.threat)
     |> assign(organisation: risk.threat.organisation)}
  end

  @impl true
  def handle_params(%{"mitigation_id" => id}, url, socket) do
    user = socket.assigns.current_user

    {:noreply,
     socket
     |> add_breadcrumbs(url)
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:mitigation, Mitigations.get_mitigation!(user, id))}
  end

  @impl true
  def handle_event("delete", %{"mitigation_id" => id}, socket) do
    current_user = socket.assigns.current_user
    organisation = socket.assigns.organisation
    risk = socket.assigns.risk
    threat = socket.assigns.threat

    {1, [_mitigation | _]} = Mitigations.delete_mitigation_by_id!(current_user, id)

    {:noreply,
     push_navigate(socket,
       to: "/organisations/#{organisation.id}/threats/#{threat.id}/risks/#{risk.id}"
     )}
  end

  defp page_title(:show), do: "Show Mitigation"
  defp page_title(:edit_mitigation), do: "Edit Mitigation"
end
