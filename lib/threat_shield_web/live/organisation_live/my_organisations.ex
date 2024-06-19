defmodule ThreatShieldWeb.OrganisationLive.MyOrganisations do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Organisations
  alias ThreatShield.Members
  alias ThreatShield.Accounts.Organisation
  alias ThreatShield.Const.Locations

  import ThreatShield.Accounts.Organisation, only: [attributes: 0]
  import ThreatShieldWeb.Helpers, only: [format_datetime: 1]

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> stream_organisations()
    |> assign(:locations_options, Locations.list_locations())
    |> assign(:attributes, attributes())
    |> assign_open_invitations()
    |> ok()
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket
    |> apply_action(socket.assigns.live_action, params)
    |> noreply()
  end

  defp apply_action(socket, :edit, %{"org_id" => id}) do
    user = socket.assigns.current_user

    socket
    |> assign(:page_title, "Edit Organisation")
    |> assign(:edit_organisation, Organisations.get_organisation!(user, id))
  end

  defp apply_action(socket, :new, _params) do
    %{current_user: current_user} = socket.assigns

    socket
    |> assign(:page_title, "New Organisation")
    |> assign(:edit_organisation, %Organisation{users: [current_user]})
    |> assign(:attributes, attributes())
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Organisations")
    |> assign(:edit_organisation, nil)
    |> assign(:attributes, attributes())
  end

  @impl true
  def handle_info(
        {ThreatShieldWeb.OrganisationLive.OrganisationForm, {:saved, organisation}},
        socket
      ) do
    {:noreply, stream_insert(socket, :organisations, organisation)}
  end

  @impl true
  def handle_event("reject_invitation", %{"invite_id" => invite_id}, socket) do
    Members.delete_invite(invite_id)

    socket
    |> assign_open_invitations()
    |> noreply()
  end

  @impl true
  def handle_event("accept_invitation", %{"invite_id" => invite_id}, socket) do
    user = socket.assigns.current_user

    case Members.accept_invite(user, invite_id) do
      {:ok, membership} ->
        socket
        |> stream_insert(:organisations, membership.organisation)
        |> assign_open_invitations()
        |> noreply()

      {:error, :already_member} ->
        socket
        |> put_flash(:info, dgettext("members", "You are already a member of this organisation."))
        |> noreply()
    end
  end

  @impl true
  def handle_event("delete", %{"org_id" => org_id}, socket) do
    user = socket.assigns.current_user
    organisation = Organisations.get_organisation!(user, org_id)
    {:ok, _} = Organisations.delete_organisation(organisation)

    socket
    |> stream_delete(:organisations, organisation)
    |> noreply()
  end

  defp stream_organisations(socket) do
    organisations = Organisations.list_organisations(socket.assigns.current_user)

    socket
    |> assign(:has_memberships, not Enum.empty?(organisations))
    |> stream(:organisations, organisations)
  end

  defp assign_open_invitations(%{assigns: %{current_user: user}} = socket) do
    open_invitations = Members.get_invites_by_user(user)

    socket
    |> assign(:open_invitations, open_invitations)
  end
end
