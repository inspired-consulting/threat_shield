defmodule ThreatShieldWeb.RiskLive.Show do
  alias ThreatShield.Organisations.Organisation
  alias ThreatShield.Mitigations.Mitigation
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Risks
  alias ThreatShield.Mitigations
  alias ThreatShield.AI

  import ThreatShieldWeb.Helpers, only: [add_breadcrumbs: 2, get_path_prefix: 1]

  @impl true
  def mount(%{"risk_id" => risk_id} = params, _session, socket) do
    user = socket.assigns.current_user
    risk = Risks.get_risk!(user, risk_id)

    {:ok,
     socket
     |> assign(risk: risk)
     |> assign(threat: risk.threat)
     |> assign(organisation: risk.threat.organisation)
     |> assign(:membership, Organisation.get_membership(risk.threat.organisation, user))
     |> assign(system: risk.threat.system)
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:asking_ai, nil)
     |> assign(:mitigation_suggestions, [])
     |> assign(:called_via_system, Map.has_key?(params, "sys_id"))}
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

  @impl true
  def handle_info({ThreatShieldWeb.RiskLive.FormComponent, {:saved, risk}}, socket) do
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
  def handle_info({ThreatShieldWeb.MitigationLive.FormComponent, {:saved, mitigation}}, socket) do
    stale_risk = socket.assigns.risk
    updated_risk = %{stale_risk | mitigations: stale_risk.mitigations ++ [mitigation]}
    {:noreply, socket |> assign(risk: updated_risk) |> assign(page_title: "Show Risk")}
  end

  def handle_info({_from, {:ai_results, new_mitigations}}, socket) do
    %{asking_ai: ref} = socket.assigns

    Process.demonitor(ref, [:flush])

    {:noreply,
     socket
     |> assign(
       asking_ai: nil,
       mitigation_suggestions: socket.assigns.mitigation_suggestions ++ new_mitigations
     )}
  end

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
  def handle_event("add_mitigation", %{"name" => name, "description" => description}, socket) do
    user = socket.assigns.current_user
    risk_id = socket.assigns.risk.id

    {:ok, mitigation} = Mitigations.add_mitigation(user, risk_id, name, description)

    suggestions =
      Enum.filter(socket.assigns.mitigation_suggestions, fn s -> s.description != description end)
      |> Enum.to_list()

    stale_risk = socket.assigns.risk
    updated_risk = %{stale_risk | mitigations: stale_risk.mitigations ++ [mitigation]}

    {:noreply,
     socket
     |> assign(:risk, updated_risk)
     |> assign(:mitigation_suggestions, suggestions)}
  end

  @impl true
  def handle_event("ignore_mitigation", %{"description" => description}, socket) do
    suggestions =
      Enum.filter(socket.assigns.mitigation_suggestions, fn s -> s.description != description end)
      |> Enum.to_list()

    {:noreply, socket |> assign(:mitigation_suggestions, suggestions)}
  end

  @impl true
  def handle_event("suggest_mitigations", %{"risk_id" => risk_id}, socket) do
    {:noreply, start_suggestions(risk_id, socket)}
  end

  defp page_title(:show), do: "Show Risk"
  defp page_title(:edit_risk), do: "Edit Risk"
  defp page_title(:new_mitigation), do: "New Mitigation"

  defp start_suggestions(risk_id, socket) do
    user = socket.assigns.current_user

    task =
      Task.Supervisor.async_nolink(ThreatShield.TaskSupervisor, fn ->
        ask_ai(user, risk_id)
      end)

    socket
    |> assign(asking_ai: task.ref)
  end

  defp ask_ai(user, risk_id) do
    risk = Risks.get_risk!(user, risk_id)

    mitigation_descriptions =
      AI.suggest_mitigations_for_risk(risk)

    {:ai_results, mitigation_descriptions}
  end
end
