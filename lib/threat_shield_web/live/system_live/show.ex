defmodule ThreatShieldWeb.SystemLive.Show do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Systems

  import ThreatShield.Systems.System, only: [attribute_keys: 0]

  @impl true
  def mount(%{"org_id" => org_id}, _session, socket) do
    user = socket.assigns.current_user

    organisation = Systems.get_organisation!(user, org_id)

    socket =
      socket
      |> assign(:organisation, organisation)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"sys_id" => id}, _, socket) do
    user = socket.assigns.current_user

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:system, Systems.get_system!(user, id))
     |> assign(:attribute_keys, attribute_keys())}
  end

  defp page_title(:show), do: "Show System"
  defp page_title(:edit), do: "Edit System"
end
