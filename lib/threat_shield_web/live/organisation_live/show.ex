defmodule ThreatShieldWeb.OrganisationLive.Show do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Organisations
  alias ThreatShield.Const.Locations

  alias ThreatShield.Systems.System

  import ThreatShield.Organisations.Organisation, only: [attribute_keys: 0]

  @impl true
  def mount(%{"org_id" => org_id}, _session, socket) do
    user = socket.assigns.current_user

    organisation = Organisations.get_organisation!(user, org_id)

    {:ok,
     socket
     |> assign(:attribute_keys, attribute_keys())
     |> assign(:organisation, organisation)
     |> assign(locations_options: Locations.list_locations())}
  end

  @impl true
  def handle_params(params, _, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket
  end

  defp apply_action(socket, :new_system, _params) do
    socket
    |> assign(:page_title, "New System")
    |> assign(:system, %System{})
  end

  @impl true
  def handle_info(
        {ThreatShieldWeb.OrganisationLive.FormComponent, {:saved, organisation}},
        socket
      ) do
    user = socket.assigns.current_user
    organisation = Organisations.get_organisation!(user, organisation.id)

    {:noreply,
     socket
     |> assign(:organisation, organisation)}
  end

  @impl true
  def handle_info({ThreatShieldWeb.SystemLive.FormComponent, {:saved, system}}, socket) do
    stale_org = socket.assigns.organisation
    updated_org = %{stale_org | systems: stale_org.systems ++ [system]}

    {:noreply,
     socket |> assign(organisation: updated_org) |> assign(page_title: "Show Organisation")}
  end

  @impl true
  def handle_event("delete", %{"organisation_id" => id}, socket) do
    current_user = socket.assigns.current_user

    {1, [_org | _]} = Organisations.delete_org_by_id!(current_user, id)

    {:noreply,
     push_navigate(socket,
       to: "/organisations"
     )}
  end
end
