defmodule ThreatShieldWeb.SystemLive.Index do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Systems
  alias ThreatShield.Systems.System

  @impl true
  def mount(%{"org_id" => org_id}, _session, socket) do
    user = socket.assigns.current_user

    membership = Systems.list_systems_for_user_and_org(user, org_id)
    organisation = membership.organisation
    systems = organisation.systems

    socket =
      socket
      |> assign(:organisation, organisation)
      |> assign(:systems, systems)

    {:ok, stream(socket, :systems, systems)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"sys_id" => id}) do
    socket
    |> assign(:page_title, "Edit System")
    |> assign(:system, Systems.get_system!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New System")
    |> assign(:system, %System{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Systems")
    |> assign(:system, nil)
  end

  @impl true
  def handle_info({ThreatShieldWeb.SystemLive.FormComponent, {:saved, system}}, socket) do
    {:noreply, stream_insert(socket, :systems, system)}
  end

  @impl true
  def handle_event("delete", %{"sys_id" => id}, socket) do
    system = Systems.get_system!(id)
    {:ok, _} = Systems.delete_system(system)

    {:noreply, stream_delete(socket, :systems, system)}
  end
end
