defmodule ThreatShieldWeb.RiskLive.RiskDetails do
  require Logger
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Threats.Threat
  alias ThreatShield.Risks
  alias ThreatShield.Risks.Risk
  alias ThreatShield.Mitigations.Mitigation
  import ThreatShieldWeb.ScopeUrlBinding

  import ThreatShieldWeb.Helpers
  import ThreatShieldWeb.Labels

  require Logger

  @moduledoc """
  Live view for showing a risk.
  The risk always belongs to a threat. But the threat may be part of a system or an asset.
  """

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(:ai_suggestions, %{})
    |> ok()
  end

  @impl true
  def handle_params(%{"risk_id" => risk_id} = params, url, socket) do
    user = socket.assigns.current_user
    risk = %Risk{} = Risks.get_risk!(user, risk_id)
    threat = %Threat{} = risk.threat
    organisation = threat.organisation

    scope = threat_scope_from_params(user, threat, params)

    socket
    |> assign(risk: risk)
    |> assign(threat: threat)
    |> assign(organisation: organisation)
    |> assign(membership: scope.membership)
    |> assign(system: threat.system)
    |> assign(scope: scope)
    |> assign(ai_suggestions: %{})
    |> assign(origin: risk_scope_to_url(scope, risk))
    |> add_breadcrumbs(url)
    |> apply_action(socket.assigns.live_action, params)
    |> noreply()
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

    socket
    |> push_navigate(to: get_path_prefix(socket.assigns) <> "/threats/#{threat.id}")
    |> noreply()
  end

  @impl true
  def handle_info({ThreatShieldWeb.RiskLive.RiskForm, {:saved, risk}}, socket) do
    user = socket.assigns.current_user
    risk = Risks.get_risk!(user, risk.id)

    socket
    |> assign(risk: risk)
    |> assign(threat: risk.threat)
    |> assign(organisation: risk.threat.organisation)
    |> assign(:page_title, page_title(socket.assigns.live_action))
    |> noreply()
  end

  @impl true
  def handle_info({ThreatShieldWeb.MitigationLive.MitigationForm, {:saved, _mitigation}}, socket) do
    socket
    |> noreply()
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
