defmodule ThreatShieldWeb.MembersLive.Index do
  @moduledoc """
  LiveView for the members index page.
  """
  alias ThreatShield.Accounts.UserNotifier
  alias ThreatShield.Accounts.Membership
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Members
  alias ThreatShield.Members.Invite

  import ThreatShieldWeb.Helpers, only: [add_breadcrumbs: 2, format_datetime: 1]
  import ThreatShieldWeb.Labels

  @impl true
  def mount(%{"org_id" => org_id}, _session, socket) do
    user = socket.assigns.current_user
    organisation = Members.get_organisation!(user, org_id)

    socket
    |> assign(:organisation, organisation)
    |> assign(
      :current_org_membership,
      organisation.memberships |> Enum.find(fn m -> m.user.id == user.id end)
    )
    |> ok()
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
  def handle_info({ThreatShieldWeb.MembersLive.InviteForm, {:saved, invite}}, socket) do
    UserNotifier.deliver_invite(invite)

    socket
    |> assign(
      organisation: %{
        socket.assigns.organisation
        | invites: socket.assigns.organisation.invites ++ [invite]
      }
    )
    |> noreply()
  end

  @impl true
  def handle_info({ThreatShieldWeb.MembersLive.RoleForm, {:saved, _membership}}, socket) do
    user = socket.assigns.current_user
    organisation = Members.get_organisation!(user, socket.assigns.organisation.id)

    socket
    |> assign(:organisation, organisation)
    |> assign(
      :current_org_membership,
      organisation.memberships |> Enum.find(fn m -> m.user.id == user.id end)
    )
    |> noreply()
  end

  @impl true
  def handle_event("delete_membership", %{"membership_id" => id}, socket) do
    user = socket.assigns.current_user
    organisation = socket.assigns.organisation

    {:ok, membership} = Members.delete_membership_by_id(user, organisation.id, id)

    user_id = user.id

    case membership do
      %Membership{user_id: ^user_id} ->
        {:noreply, push_navigate(socket, to: ~p"/organisations")}

      membership ->
        socket
        |> assign(
          organisation: %{
            socket.assigns.organisation
            | memberships: delete_by_id(socket.assigns.organisation.memberships, membership.id)
          }
        )
        |> noreply()
    end
  end

  @impl true
  def handle_event("edit_membership", %{"membership_id" => id}, socket) do
    organisation = socket.assigns.organisation

    socket
    |> assign(:live_action, :edit_membership)
    |> assign(
      :membership_to_edit,
      Enum.find(organisation.memberships, fn m -> m.id == String.to_integer(id) end)
    )
    |> noreply()
  end

  @impl true
  def handle_event("revoke_invite", %{"invite_id" => id}, socket) do
    user = socket.assigns.current_user

    {:ok, invite} = Members.delete_invite_by_id(user, id)

    socket
    |> assign(
      organisation: %{
        socket.assigns.organisation
        | invites: delete_by_id(socket.assigns.organisation.invites, invite.id)
      }
    )
    |> noreply()
  end

  defp delete_by_id(list, id) do
    index = Enum.find_index(list, fn item -> item.id == id end)
    List.delete_at(list, index)
  end
end
