defmodule ThreatShieldWeb.MembersLive.Index do
  alias ThreatShield.Accounts.UserNotifier
  alias ThreatShield.Organisations.Membership
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Members
  alias ThreatShield.Members.Invite

  import ThreatShieldWeb.Helpers, only: [add_breadcrumbs: 2]

  @impl true
  def mount(%{"org_id" => org_id}, _session, socket) do
    user = socket.assigns.current_user
    organisation = Members.get_organisation!(user, org_id)

    {:ok,
     socket
     |> assign(:organisation, organisation)}
  end

  @impl true
  def handle_params(params, url, socket) do
    {:noreply,
     socket
     |> add_breadcrumbs(url)
     |> apply_action(socket.assigns.live_action, params)}
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
  def handle_info({ThreatShieldWeb.MembersLive.FormComponent, {:saved, invite}}, socket) do
    UserNotifier.deliver_invite(invite)

    {:noreply,
     socket
     |> assign(
       organisation: %{
         socket.assigns.organisation
         | invites: socket.assigns.organisation.invites ++ [invite]
       }
     )}
  end

  @impl true
  def handle_event("delete_membership", %{"membership_id" => id}, socket) do
    user = socket.assigns.current_user
    organisation = socket.assigns.organisation

    {:ok, membership} = Members.delete_membership_by_id(user, organisation.id, id)

    user_id = user.id

    case membership do
      %Membership{user_id: ^user_id} ->
        {:noreply, push_navigate(socket, to: "/dashboard")}

      membership ->
        {:noreply,
         socket
         |> assign(
           organisation: %{
             socket.assigns.organisation
             | memberships: delete_by_id(socket.assigns.organisation.memberships, membership.id)
           }
         )}
    end
  end

  @impl true
  def handle_event("revoke_invite", %{"invite_id" => id}, socket) do
    user = socket.assigns.current_user

    {:ok, invite} = Members.delete_invite_by_id(user, id)

    {:noreply,
     socket
     |> assign(
       organisation: %{
         socket.assigns.organisation
         | invites: delete_by_id(socket.assigns.organisation.invites, invite.id)
       }
     )}
  end

  defp delete_by_id(list, id) do
    index = Enum.find_index(list, fn item -> item.id == id end)
    List.delete_at(list, index)
  end
end
