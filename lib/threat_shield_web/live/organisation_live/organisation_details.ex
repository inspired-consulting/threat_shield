defmodule ThreatShieldWeb.OrganisationLive.OrganisationDetails do
  alias ThreatShield.Accounts.Organisation
  use ThreatShieldWeb, :live_view

  require Logger

  alias ThreatShield.Organisations
  alias ThreatShield.Const.Locations

  alias ThreatShield.Assets
  alias ThreatShield.Threats

  import ThreatShield.Accounts.Organisation,
    only: [attributes: 0]

  alias ThreatShield.Scope

  import ThreatShieldWeb.Helpers, only: [add_breadcrumbs: 2, convert_date: 1, link_to: 1]

  @impl true
  def mount(%{"org_id" => org_id} = _params, _session, socket) do
    user = socket.assigns.current_user

    organisation = Organisations.get_organisation!(user, org_id)
    membership = Organisation.get_membership(organisation, user)

    threat_count = Threats.count_all_threats(organisation)
    asset_count = Assets.count_all_assets()

    socket
    |> assign(:current_tab, :systems)
    |> assign(:attributes, attributes())
    |> assign(:organisation, organisation)
    |> assign(:membership, membership)
    |> assign(locations_options: Locations.list_locations())
    |> assign(:attributes, Organisation.attributes())
    |> assign(:threat_count, threat_count)
    |> assign(:asset_count, asset_count)
    |> assign(:scope, Scope.for(user, organisation))
    |> assign(:ai_suggestions, %{})
    |> ok()
  end

  @impl true
  def handle_params(params, url, socket) do
    socket
    |> add_breadcrumbs(url)
    |> apply_action(socket.assigns.live_action, params)
    |> noreply()
  end

  defp apply_action(socket, :show, _params) do
    socket
  end

  defp apply_action(socket, :edit_organisation, _params) do
    socket
    |> assign(:page_title, "Edit Organisation")
  end

  @impl true
  def handle_info(
        {ThreatShieldWeb.OrganisationLive.OrganisationForm, {:saved, organisation}},
        socket
      ) do
    user = socket.assigns.current_user
    organisation = Organisations.get_organisation!(user, organisation.id)

    {:noreply,
     socket
     |> assign(:organisation, organisation)}
  end

  @impl true
  def handle_info({ThreatShieldWeb.SystemLive.SystemForm, {:saved, system}}, socket) do
    stale_org = socket.assigns.organisation
    updated_org = %{stale_org | systems: stale_org.systems ++ [system]}

    {:noreply,
     socket |> assign(organisation: updated_org) |> assign(page_title: "Show Organisation")}
  end

  @impl true
  def handle_info({ThreatShieldWeb.AssetLive.AssetForm, {:saved, asset}}, socket) do
    stale_org = socket.assigns.organisation
    updated_org = %{stale_org | assets: stale_org.assets ++ [asset]}

    {:noreply,
     socket |> assign(organisation: updated_org) |> assign(page_title: "Show Organisation")}
  end

  @impl true
  def handle_info({ThreatShieldWeb.ThreatLive.ThreatForm, {:saved, threat}}, socket) do
    stale_org = socket.assigns.organisation
    user = socket.assigns.current_user

    new_threat_with_system = Threats.get_threat!(user, threat.id)
    updated_org = %{stale_org | threats: stale_org.threats ++ [new_threat_with_system]}

    {:noreply,
     socket |> assign(organisation: updated_org) |> assign(page_title: "Show Organisation")}
  end

  @impl true
  def handle_info({task_ref, {:new_ai_suggestion, suggestion}}, socket) do
    %{type: entity_type, result: result} = suggestion

    # stop monitoring the task
    Process.demonitor(task_ref, [:flush])

    suggestions =
      (socket.assigns[:suggestions] || %{})
      |> Map.put(entity_type, result)

    socket
    |> assign(ai_suggestions: suggestions)
    |> noreply()
  end

  @impl true
  def handle_event("delete", %{"organisation_id" => id}, socket) do
    current_user = socket.assigns.current_user

    {1, [_org | _]} = Organisations.delete_org_by_id!(current_user, id)

    socket
    |> push_navigate(to: ~p"/organisations")
    |> noreply()
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    socket
    |> assign(current_tab: String.to_existing_atom(tab))
    |> noreply()
  end
end
