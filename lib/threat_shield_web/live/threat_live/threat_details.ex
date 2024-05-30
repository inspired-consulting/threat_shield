defmodule ThreatShieldWeb.ThreatLive.ThreatDetails do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Scope
  alias ThreatShield.Threats
  alias ThreatShield.Threats.Threat
  alias ThreatShield.Risks.Risk

  import ThreatShield.Accounts.Organisation,
    only: [list_system_options: 1, list_asset_options: 1]

  import ThreatShieldWeb.ScopeUrlBinding
  import ThreatShieldWeb.Helpers, only: [add_breadcrumbs: 2, get_path_prefix: 1]
  import ThreatShieldWeb.Labels

  @impl true
  def mount(%{"threat_id" => threat_id} = params, _session, socket) do
    user = socket.assigns.current_user
    threat = %Threat{} = Threats.get_threat!(user, threat_id)
    scope = %Scope{} = threat_scope_from_params(user, threat, params)

    socket
    |> assign(scope: scope)
    |> assign(organisation: threat.organisation)
    |> assign(system: threat.system)
    |> assign(asset: threat.asset)
    |> assign(threat: threat)
    |> assign(page_title: page_title(socket.assigns.live_action))
    |> assign(system_options: list_system_options(threat.organisation))
    |> assign(asset_options: list_asset_options(threat.organisation))
    |> assign(origin: threat_scope_to_url(scope))
    |> assign(ai_suggestions: %{})
    |> ok()
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
  def handle_params(params, url, socket) do
    {:noreply,
     socket
     |> add_breadcrumbs(url)
     |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("delete", %{"threat_id" => id}, socket) do
    user =
      socket.assigns.current_user

    {:ok, _} = Threats.delete_threat_by_id(user, id)

    {:noreply, push_navigate(socket, to: get_path_prefix(socket.assigns))}
  end

  @impl true
  def handle_info({ThreatShieldWeb.RiskLive.RiskForm, {:saved, risk}}, socket) do
    stale_threat = socket.assigns.threat
    updated_threat = %{stale_threat | risks: stale_threat.risks ++ [risk]}
    {:noreply, socket |> assign(threat: updated_threat) |> assign(page_title: "Show threat")}
  end

  @impl true
  def handle_info({ThreatShieldWeb.ThreatLive.ThreatForm, {:saved, threat}}, socket) do
    current_user = socket.assigns.current_user
    threat = Threats.get_threat!(current_user, threat.id)

    socket =
      socket
      |> assign(:threat, threat)
      |> assign(:organisation, threat.organisation)
      |> assign(:page_title, page_title(socket.assigns.live_action))

    {:noreply, socket}
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

  defp page_title(:show), do: "Show Threat"
  defp page_title(:edit_threat), do: "Edit Threat"
  defp page_title(:new_risk), do: "New Risk"
end
