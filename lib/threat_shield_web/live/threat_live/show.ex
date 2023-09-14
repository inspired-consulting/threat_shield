defmodule ThreatShieldWeb.ThreatLive.Show do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Threats
  alias ThreatShield.Risks.Risk
  alias ThreatShield.Risks
  alias ThreatShield.AI

  import ThreatShield.Threats.Threat, only: [system_name: 1]
  import ThreatShield.Organisations.Organisation, only: [list_system_options: 1]
  import ThreatShieldWeb.Helpers, only: [add_breadcrumbs: 2]

  @impl true
  def mount(%{"threat_id" => threat_id} = params, _session, socket) do
    current_user = socket.assigns.current_user
    threat = Threats.get_threat!(current_user, threat_id)

    socket =
      socket
      |> assign(:threat, threat)
      |> assign(:organisation, threat.organisation)
      |> assign(:system, threat.system)
      |> assign(:page_title, page_title(socket.assigns.live_action))
      |> assign(:asking_ai, nil)
      |> assign(:risk_suggestions, [])
      |> assign(:called_via_system, Map.has_key?(params, "sys_id"))

    socket_with_options =
      if socket.assigns.called_via_system do
        socket
      else
        assign(socket, :system_options, list_system_options(threat.organisation))
      end

    {:ok, socket_with_options}
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
  def handle_event("add", %{"name" => name, "description" => description}, socket) do
    user = socket.assigns.current_user
    threat_id = socket.assigns.threat.id

    {:ok, risk} = Risks.add_risk(user, threat_id, name, description)

    suggestions =
      Enum.filter(socket.assigns.risk_suggestions, fn s -> s.description != description end)
      |> Enum.to_list()

    stale_threat = socket.assigns.threat
    updated_threat = %{stale_threat | risks: stale_threat.risks ++ [risk]}

    {:noreply,
     socket
     |> assign(:threat, updated_threat)
     |> assign(:risk_suggestions, suggestions)}
  end

  @impl true
  def handle_event("ignore", %{"description" => description}, socket) do
    suggestions =
      Enum.filter(socket.assigns.risk_suggestions, fn s -> s.description != description end)
      |> Enum.to_list()

    {:noreply, socket |> assign(:risk_suggestions, suggestions)}
  end

  @impl true
  def handle_event("suggest_risks", %{"threat_id" => threat_id}, socket) do
    {:noreply, start_suggestions(threat_id, socket)}
  end

  @impl true
  def handle_info({ThreatShieldWeb.RiskLive.FormComponent, {:saved, risk}}, socket) do
    stale_threat = socket.assigns.threat
    updated_threat = %{stale_threat | risks: stale_threat.risks ++ [risk]}
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

  def handle_info({_from, {:ai_results, new_risks}}, socket) do
    %{asking_ai: ref} = socket.assigns

    Process.demonitor(ref, [:flush])

    {:noreply,
     socket
     |> assign(
       asking_ai: nil,
       risk_suggestions: socket.assigns.risk_suggestions ++ new_risks
     )}
  end

  defp page_title(:show), do: "Show Threat"
  defp page_title(:edit_threat), do: "Edit Threat"
  defp page_title(:new_risk), do: "New Risk"

  defp start_suggestions(threat_id, socket) do
    user = socket.assigns.current_user

    task =
      Task.Supervisor.async_nolink(ThreatShield.TaskSupervisor, fn ->
        ask_ai(user, threat_id)
      end)

    socket
    |> assign(asking_ai: task.ref)
  end

  defp ask_ai(user, threat_id) do
    threat = Threats.get_threat!(user, threat_id)

    risk_descriptions =
      AI.suggest_risks_for_threat(threat)

    {:ai_results, risk_descriptions}
  end

  defp get_path_prefix(assigns) do
    if assigns.called_via_system do
      case assigns[:system] do
        nil -> "/organisations/#{assigns.organisation.id}"
        system -> "/organisations/#{assigns.organisation.id}/systems/#{system.id}"
      end
    else
      "/organisations/#{assigns.organisation.id}"
    end
  end
end
