defmodule ThreatShieldWeb.OrganisationLive.Index do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Organisations
  alias ThreatShield.Organisations.Organisation
  alias ThreatShield.Const.Locations

  import ThreatShield.Organisations.Organisation, only: [attributes: 0]

  @impl true
  def mount(_params, _session, socket) do
    locations_options = Locations.list_locations()

    case Organisations.list_organisations(socket.assigns.current_user) do
      [single_org] ->
        socket
        |> redirect(to: ~p"/organisations/#{single_org.id}")
        |> ok()

      organisations ->
        socket
        |> assign(locations_options: locations_options)
        |> stream_organisations(organisations)
        |> assign(:attributes, attributes())
        |> ok()
    end
  end

  defp stream_organisations(socket, organisations) do
    stream(
      socket,
      :organisations,
      organisations
    )
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
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
        {ThreatShieldWeb.OrganisationLive.FormComponent, {:saved, organisation}},
        socket
      ) do
    {:noreply, stream_insert(socket, :organisations, organisation)}
  end

  @impl true
  def handle_event("delete", %{"org_id" => org_id}, socket) do
    user = socket.assigns.current_user
    organisation = Organisations.get_organisation!(user, org_id)
    {:ok, _} = Organisations.delete_organisation(organisation)

    {:noreply, stream_delete(socket, :organisations, organisation)}
  end
end
