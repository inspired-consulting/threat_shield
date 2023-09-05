defmodule ThreatShieldWeb.ThreatLive.Index do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Threats
  alias ThreatShield.Threats.Threat
  alias ThreatShield.AI

  import ThreatShield.Threats.Threat,
    only: [system_name: 1]

  import ThreatShield.Organisations.Organisation, only: [list_system_options: 1]

  @impl true
  def mount(%{"org_id" => org_id}, _session, socket) do
    current_user = socket.assigns.current_user
    organisation = Threats.get_organisation!(current_user, org_id)
    threats = organisation.threats

    {:ok,
     socket
     |> assign(
       organisation: organisation,
       asking_ai: nil,
       threat_suggestions: []
     )
     |> stream(:threats, threats)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"threat_id" => id}) do
    user = socket.assigns.current_user

    socket
    |> assign(:page_title, "Edit Threat")
    |> assign(:threat, Threats.get_threat!(user, id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Threat")
    |> assign(:threat, %Threat{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Threats")
    |> assign(:threat, nil)
  end

  @impl true
  def handle_info({ThreatShieldWeb.ThreatLive.FormComponent, {:saved, threat}}, socket) do
    {:noreply, stream_insert(socket, :threats, threat)}
  end

  def handle_info({_from, {:ai_results, new_threats}}, socket) do
    %{asking_ai: ref} = socket.assigns

    Process.demonitor(ref, [:flush])

    {:noreply,
     socket
     |> assign(
       asking_ai: nil,
       threat_suggestions: socket.assigns.threat_suggestions ++ new_threats
     )}
  end

  @impl true
  def handle_event("add", %{"description" => description}, socket) do
    user = socket.assigns.current_user
    org_id = socket.assigns.organisation.id

    {:ok, threat} = Threats.add_threat_with_description(user, org_id, description)

    suggestions =
      Enum.filter(socket.assigns.threat_suggestions, fn s -> s.description != description end)
      |> Enum.to_list()

    {:noreply,
     socket
     |> stream_insert(:threats, threat)
     |> assign(:threat_suggestions, suggestions)}
  end

  @impl true
  def handle_event("delete", %{"description" => description}, socket) do
    suggestions =
      Enum.filter(socket.assigns.threat_suggestions, fn s -> s.description != description end)
      |> Enum.to_list()

    {:noreply, socket |> assign(:threat_suggestions, suggestions)}
  end

  @impl true
  def handle_event("suggest", %{"org_id" => org_id}, socket) do
    user = socket.assigns.current_user

    task =
      Task.Supervisor.async_nolink(ThreatShield.TaskSupervisor, fn ->
        ask_ai(user, org_id)
      end)

    socket =
      socket
      |> assign(asking_ai: task.ref)

    {:noreply, socket}
  end

  defp ask_ai(user, org_id) do
    organisation = Threats.get_organisation!(user, org_id)

    threat_descriptions =
      AI.suggest_threats_for_organisation(organisation)

    {:ai_results, threat_descriptions}
  end
end
