defmodule ThreatShieldWeb.MembersLive.Join do
  alias ThreatShield.Members
  use ThreatShieldWeb, :live_view

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    {:ok,
     socket
     |> assign(invite: Members.get_invite_by_token(token))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :join, _params) do
    socket
    |> assign(:page_title, "Join organisation")
  end

  @impl true
  def handle_event("join", %{"token" => token}, socket) do
    user = socket.assigns.current_user

    {:ok, membership} = Members.join_with_token(user, token)

    {:noreply,
     push_navigate(socket,
       to: "/organisations/" <> Integer.to_string(membership.organisation_id)
     )}
  end
end
