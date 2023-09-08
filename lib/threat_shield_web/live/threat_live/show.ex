defmodule ThreatShieldWeb.ThreatLive.Show do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Threats
  alias ThreatShield.Risks.Risk

  import ThreatShield.Threats.Threat, only: [system_name: 1]
  import ThreatShield.Organisations.Organisation, only: [list_system_options: 1]

  @impl true
  def mount(%{"threat_id" => threat_id}, _session, socket) do
    current_user = socket.assigns.current_user
    threat = Threats.get_threat!(current_user, threat_id)

    socket =
      socket
      |> assign(:threat, threat)
      |> assign(:organisation, threat.organisation)
      |> assign(:page_title, page_title(socket.assigns.live_action))

    {:ok, socket}
  end

  defp apply_action(socket, :new_risk, _params) do
    socket
    |> assign(:page_title, "New Risk")
    |> assign(:risk, %Risk{})
  end

  defp apply_action(socket, :show, _params) do
    socket
  end

  defp apply_action(socket, :edit_threat, _params) do
    socket
    |> assign(:page_title, "Edit Threat")
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("delete", %{"threat_id" => id}, socket) do
    user =
      socket.assigns.current_user

    {:ok, _} = Threats.delete_threat_by_id(user, id)

    organisation = socket.assigns.organisation

    {:noreply, push_navigate(socket, to: "/organisations/#{organisation.id}/threats")}
  end

  @impl true
  def handle_info({ThreatShieldWeb.RiskLive.FormComponent, {:saved, risk}}, socket) do
    stale_threat = socket.assigns.threat
    updated_threat = %{stale_threat | risks: [risk | stale_threat.risks]}
    {:noreply, socket |> assign(threat: updated_threat) |> assign(page_title: "Show threat")}
  end

  @impl true
  def handle_info({ThreatShieldWeb.ThreatLive.FormComponent, {:saved, threat}}, socket) do
    current_user = socket.assigns.current_user
    threat = Threats.get_threat!(current_user, threat.id)

    socket =
      socket
      |> assign(:threat, threat)
      |> assign(:organisation, threat.organisation)
      |> assign(:page_title, page_title(socket.assigns.live_action))

    {:noreply, socket}
  end

  defp page_title(:show), do: "Show Threat"
  defp page_title(:edit_threat), do: "Edit Threat"
  defp page_title(:new_risk), do: "New Risk"
end
