defmodule ThreatShieldWeb.RiskLive.Show do
  alias ThreatShield.Organisations.Organisation
  alias ThreatShield.Mitigations.Mitigation
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Scope
  alias ThreatShield.Risks
  alias ThreatShield.Risks.Risk

  import ThreatShieldWeb.Helpers

  @impl true
  def mount(%{"risk_id" => risk_id} = params, _session, socket) do
    user = socket.assigns.current_user
    risk = Risks.get_risk!(user, risk_id)
    threat = risk.threat
    organisation = threat.organisation

    socket
    |> assign(risk: risk)
    |> assign(threat: threat)
    |> assign(organisation: organisation)
    |> assign(:membership, Organisation.get_membership(organisation, user))
    |> assign(system: threat.system)
    |> assign(:scope, Scope.for(user, organisation, threat.system))
    |> assign(:mitigation_suggestions, [])
    |> assign(:called_via_system, Map.has_key?(params, "sys_id"))
    |> assign(:ai_suggestions, %{})
    |> ok()
  end

  @impl true
  def handle_params(params, url, socket) do
    {:noreply,
     socket
     |> add_breadcrumbs(url)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit_risk, _params) do
    socket
    |> assign(:page_title, "Edit Risk")
  end

  defp apply_action(socket, :show, _params) do
    socket
  end

  defp apply_action(socket, :new_mitigation, _params) do
    socket
    |> assign(:page_title, "New Mitigation")
    |> assign(:mitigation, %Mitigation{})
  end

  # events and notifications

  @impl true
  def handle_event("delete", %{"risk_id" => id}, socket) do
    current_user = socket.assigns.current_user
    threat = socket.assigns.threat

    {1, [_risk | _]} = Risks.delete_risk_by_id!(current_user, id)

    {:noreply,
     push_navigate(socket,
       to: get_path_prefix(socket.assigns) <> "/threats/#{threat.id}"
     )}
  end

  @impl true
  def handle_info({ThreatShieldWeb.RiskLive.RiskForm, {:saved, risk}}, socket) do
    user = socket.assigns.current_user
    risk = Risks.get_risk!(user, risk.id)

    {:noreply,
     socket
     |> assign(risk: risk)
     |> assign(threat: risk.threat)
     |> assign(organisation: risk.threat.organisation)
     |> assign(:page_title, page_title(socket.assigns.live_action))}
  end

  @impl true
  def handle_info({ThreatShieldWeb.MitigationLive.MitigationForm, {:saved, mitigation}}, socket) do
    stale_risk = socket.assigns.risk
    updated_risk = %{stale_risk | mitigations: stale_risk.mitigations ++ [mitigation]}
    {:noreply, socket |> assign(risk: updated_risk) |> assign(page_title: "Show Risk")}
  end

  @impl true
  def handle_info({task_ref, {:new_ai_suggestion, suggestion}}, socket) do
    %{type: entity_type, result: result} = suggestion

    # stop monitoring the task
    Process.demonitor(task_ref, [:flush])

    suggestions =
      (socket.assigns[:suggestions] || %{})
      |> Map.put(entity_type, result)

    socket
    |> assign(ai_suggestions: suggestions)
    |> noreply()
  end

  defp page_title(:show), do: "Show Risk"
  defp page_title(:edit_risk), do: "Edit Risk"
  defp page_title(:new_mitigation), do: "New Mitigation"
end
