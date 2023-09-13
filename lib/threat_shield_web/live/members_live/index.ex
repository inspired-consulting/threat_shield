defmodule ThreatShieldWeb.MembersLive.Index do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Members
  alias ThreatShield.Members.Invite

  @impl true
  def mount(%{"org_id" => org_id}, _session, socket) do
    user = socket.assigns.current_user
    organisation = Members.get_organisation!(user, org_id)

    {:ok,
     socket
     |> assign(:organisation, organisation)
     |> stream(:memberships, organisation.memberships)
     |> stream(:invites, organisation.invites)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new_invite, _params) do
    socket
    |> assign(:page_title, "Invite new member")
    |> assign(:invite, %Invite{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Members")
    |> assign(:invite, nil)
  end

  @impl true
  def handle_info({ThreatShieldWeb.MembersLive.FormComponent, {:saved, invites}}, socket) do
    {:noreply, stream_insert(socket, :invites, invites)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    invites = Members.get_invites!(id)
    {:ok, _} = Members.delete_invites(invites)

    {:noreply, stream_delete(socket, :invites_collection, invites)}
  end
end
