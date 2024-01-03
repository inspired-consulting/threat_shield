defmodule ThreatShieldWeb.MitigationLive.Show do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Mitigations
  alias ThreatShield.Organisations.Organisation

  import ThreatShieldWeb.Helpers, only: [add_breadcrumbs: 2, get_path_prefix: 1]

  @impl true
  def mount(%{"mitigation_id" => mitigation_id} = params, _session, socket) do
    user = socket.assigns.current_user
    mitigation = Mitigations.get_mitigation!(user, mitigation_id)

    {:ok,
     socket
     |> assign(mitigation: mitigation)
     |> assign(risk: mitigation.risk)
     |> assign(threat: mitigation.risk.threat)
     |> assign(organisation: mitigation.risk.threat.organisation)
     |> assign(
       :membership,
       Organisation.get_membership(mitigation.risk.threat.organisation, user)
     )
     |> assign(system: mitigation.risk.threat.system)
     |> assign(:called_via_system, Map.has_key?(params, "sys_id"))}
  end

  @impl true
  def handle_params(_, url, socket) do
    {:noreply,
     socket
     |> add_breadcrumbs(url)
     |> assign(:page_title, page_title(socket.assigns.live_action))}
  end

  @impl true
  def handle_event("delete", %{"mitigation_id" => id}, socket) do
    current_user = socket.assigns.current_user
    risk = socket.assigns.risk
    threat = socket.assigns.threat

    {1, [_mitigation | _]} = Mitigations.delete_mitigation_by_id!(current_user, id)

    {:noreply,
     push_navigate(socket,
       to: get_path_prefix(socket.assigns) <> "/threats/#{threat.id}/risks/#{risk.id}"
     )}
  end

  @impl true
  def handle_info(
        {ThreatShieldWeb.MitigationLive.MitigationForm, {:saved, mitigation}},
        socket
      ) do
    mitigation = Mitigations.get_mitigation!(socket.assigns.current_user, mitigation.id)

    {:noreply,
     socket
     |> assign(mitigation: mitigation)
     |> assign(page_title: "Show Mitigation")}
  end

  defp page_title(:show), do: "Show Mitigation"
  defp page_title(:edit_mitigation), do: "Edit Mitigation"
end
