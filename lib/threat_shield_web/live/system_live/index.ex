defmodule ThreatShieldWeb.SystemLive.Index do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Systems
  alias ThreatShield.Systems.System

  @attribute_keys ["Database", "Application Framework", "Authentication Framework"]

  @impl true
  def mount(%{"org_id" => org_id}, _session, socket) do
    user = socket.assigns.current_user

    organisation = Systems.get_organisation!(user, org_id)
    systems = organisation.systems

    socket =
      socket
      |> assign(:organisation, organisation)
      |> assign(:systems, systems)
      |> assign(:attribute_keys, @attribute_keys)

    {:ok, stream(socket, :systems, systems)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"sys_id" => id}) do
    user = socket.assigns.current_user

    socket
    |> assign(:page_title, "Edit System")
    |> assign(:system, Systems.get_system!(user, id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New System")
    |> assign(:system, %System{})
    |> assign(:attribute_keys, @attribute_keys)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Systems")
    |> assign(:system, nil)
    |> assign(:attribute_keys, @attribute_keys)
  end

  @impl true
  def handle_info({ThreatShieldWeb.SystemLive.FormComponent, {:saved, system}}, socket) do
    {:noreply, stream_insert(socket, :systems, system)}
  end

  @impl true
  def handle_event("delete", %{"sys_id" => id}, socket) do
    user = socket.assigns.current_user
    organisation = socket.assigns.organisation

    system = Systems.get_system!(user, id)
    {:ok, _} = Systems.delete_system(user, organisation, system)

    {:noreply, stream_delete(socket, :systems, system)}
  end
end
