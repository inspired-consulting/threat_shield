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

    socket =
      socket
      |> assign(
        organisation: organisation,
        asking_ai: nil
      )

    {:ok, stream(socket, :threats, threats)}
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
    {:noreply, socket |> assign(asking_ai: nil) |> stream(:threats, new_threats)}
  end

  @impl true
  def handle_event("add", %{"threat_id" => id}, socket) do
    user = socket.assigns.current_user
    {:ok, threat} = Threats.add_threat_by_id(user, id)

    {:noreply, stream_insert(socket, :threats, threat)}
  end

  @impl true
  def handle_event("delete", %{"threat_id" => id}, socket) do
    user =
      socket.assigns.current_user

    threat = Threats.get_threat!(user, id)
    {:ok, _} = Threats.delete_threat_by_id(user, id)

    {:noreply, stream_delete(socket, :threats, threat)}
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

    new_threats =
      Threats.bulk_add_for_user_and_org(user, organisation, threat_descriptions)

    {:ai_results, new_threats}
  end
end
