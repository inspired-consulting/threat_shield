defmodule ThreatShieldWeb.ThreatLive.Show do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Threats
  alias ThreatShield.Organisations

  @impl true
  def mount(%{"org_id" => org_id}, _session, socket) do
    current_user = socket.assigns.current_user
    organisation = Organisations.get_organisation_for_user!(org_id, current_user)

    socket =
      socket
      |> assign(:organisation, organisation)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"threat_id" => id}, _, socket) do
    user =
      socket.assigns.current_user

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:threat, Threats.get_threat!(user, id))}
  end

  @impl true
  def handle_event("delete", %{"threat_id" => id}, socket) do
    user =
      socket.assigns.current_user

    threat = Threats.get_threat!(user, id)
    {:ok, _} = Threats.delete_threat_by_id(user, id)

    {:noreply, stream_delete(socket, :threats, threat)}
  end

  defp page_title(:show), do: "Show Threat"
  defp page_title(:edit), do: "Edit Threat"
end
