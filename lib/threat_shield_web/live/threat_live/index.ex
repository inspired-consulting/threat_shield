defmodule ThreatShieldWeb.ThreatLive.Index do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Threats
  alias ThreatShield.Threats.Threat
  alias ThreatShield.Systems
  alias ThreatShield.AI

  @impl true
  def mount(%{"org_id" => org_id, "sys_id" => sys_id}, _session, socket) do
    current_user = socket.assigns.current_user
    system = Threats.get_system_with_threats(current_user, org_id, sys_id)
    threats = system.threats

    socket =
      socket
      |> assign(:organisation, system.organisation)
      |> assign(:system, system)

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

  @impl true
  def handle_event("delete", %{"threat_id" => id}, socket) do
    user = socket.assigns.current_user
    threat = Threats.get_threat!(user, id)
    {:ok, _} = Threats.delete_threat_by_id(user, id)

    {:noreply, stream_delete(socket, :threats, threat)}
  end

  @impl true
  def handle_event("ignore", %{"threat_id" => id}, socket) do
    user = socket.assigns.current_user
    {:ok, threat} = Threats.ignore_threat_by_id(user, id)

    {:noreply, stream_insert(socket, :threats, threat)}
  end

  @impl true
  def handle_event("add", %{"threat_id" => id}, socket) do
    user = socket.assigns.current_user
    {:ok, threat} = Threats.add_threat_by_id(user, id)

    {:noreply, stream_insert(socket, :threats, threat)}
  end

  @impl true
  def handle_event("suggest", %{"sys_id" => sys_id}, socket) do
    user = socket.assigns.current_user

    system = Systems.get_system_for_user(user, sys_id)
    organisation = system.organisation

    threats =
      AI.suggest_initial_threats(organisation, system)
      |> IO.inspect(label: "#{__ENV__.file}:#{__ENV__.line}")

    new_threats = Threats.bulk_add_for_user_and_system(user, system, threats)

    {:noreply, stream(socket, :threats, new_threats)}
  end
end
