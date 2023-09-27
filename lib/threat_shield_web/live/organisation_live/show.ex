defmodule ThreatShieldWeb.OrganisationLive.Show do
  alias ThreatShield.Organisations.Organisation
  alias ThreatShield.Threats.Threat
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Organisations
  alias ThreatShield.Const.Locations

  alias ThreatShield.Assets
  alias ThreatShield.Threats
  alias ThreatShield.Assets.Asset
  alias ThreatShield.Systems.System
  alias ThreatShield.AI

  import ThreatShield.Organisations.Organisation,
    only: [attributes: 0, list_system_options: 1]

  import ThreatShieldWeb.Helpers, only: [add_breadcrumbs: 2]

  @impl true
  def mount(%{"org_id" => org_id} = params, _session, socket) do
    user = socket.assigns.current_user

    organisation = Organisations.get_organisation!(user, org_id)
    membership = Organisation.get_membership(organisation, user)

    suggest_threats = Map.has_key?(params, "suggest_threats")

    threat_count = Threats.count_all_threats()
    asset_count = Assets.count_all_assets()

    socket =
      socket
      |> assign(:attributes, attributes())
      |> assign(:organisation, organisation)
      |> assign(:entity_page, :organisation)
      |> assign(:membership, membership)
      |> assign(locations_options: Locations.list_locations())
      |> assign(:attributes, Organisation.attributes())
      |> assign(:asking_ai_for_assets, nil)
      |> assign(:asking_ai_for_threats, nil)
      |> assign(:asset_suggestions, [])
      |> assign(:threat_suggestions, [])
      |> assign(:threat_count, threat_count)
      |> assign(:asset_count, asset_count)

    socket_with_suggestions =
      if suggest_threats do
        start_threat_suggestions(socket.assigns.organisation.id, socket)
      else
        socket
      end

    {:ok, socket_with_suggestions}
  end

  @impl true
  def handle_params(params, url, socket) do
    {:noreply,
     socket
     |> add_breadcrumbs(url)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket
  end

  defp apply_action(socket, :edit_organisation, _params) do
    socket
    |> assign(:page_title, "Edit Organisation")
  end

  defp apply_action(socket, :new_system, _params) do
    socket
    |> assign(:page_title, "New System")
    |> assign(:system, %System{})
  end

  defp apply_action(socket, :new_asset, _params) do
    socket
    |> assign(:page_title, "New Asset")
    |> assign(:asset, %Asset{})
  end

  defp apply_action(socket, :new_threat, _params) do
    socket
    |> assign(:page_title, "New Threat")
    |> assign(:threat, %Threat{})
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
  def handle_info({ThreatShieldWeb.AssetLive.FormComponent, {:saved, asset}}, socket) do
    stale_org = socket.assigns.organisation
    updated_org = %{stale_org | assets: stale_org.assets ++ [asset]}

    {:noreply,
     socket |> assign(organisation: updated_org) |> assign(page_title: "Show Organisation")}
  end

  @impl true
  def handle_info({ThreatShieldWeb.ThreatLive.FormComponent, {:saved, threat}}, socket) do
    stale_org = socket.assigns.organisation
    user = socket.assigns.current_user

    new_threat_with_system = Threats.get_threat!(user, threat.id)
    updated_org = %{stale_org | threats: stale_org.threats ++ [new_threat_with_system]}

    {:noreply,
     socket |> assign(organisation: updated_org) |> assign(page_title: "Show Organisation")}
  end

  def handle_info({_from, {:ai_results_assets, new_assets}}, socket) do
    %{asking_ai_for_assets: ref} = socket.assigns

    Process.demonitor(ref, [:flush])

    {:noreply,
     socket
     |> assign(
       asking_ai_for_assets: nil,
       asset_suggestions: socket.assigns.asset_suggestions ++ new_assets
     )}
  end

  def handle_info({_from, {:ai_results_threats, new_threats}}, socket) do
    %{asking_ai_for_threats: ref} = socket.assigns

    Process.demonitor(ref, [:flush])

    {:noreply,
     socket
     |> assign(
       asking_ai_for_threats: nil,
       threat_suggestions: socket.assigns.threat_suggestions ++ new_threats
     )}
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

  @impl true
  def handle_event("suggest_assets", %{"org_id" => org_id}, socket) do
    user = socket.assigns.current_user

    task =
      Task.Supervisor.async_nolink(ThreatShield.TaskSupervisor, fn ->
        ask_ai_for_assets(user, org_id)
      end)

    socket =
      socket
      |> assign(asking_ai_for_assets: task.ref)

    {:noreply, socket}
  end

  @impl true
  def handle_event("suggest_threats", %{"org_id" => org_id}, socket) do
    {:noreply, start_threat_suggestions(org_id, socket)}
  end

  @impl true
  def handle_event("ignore_asset", %{"description" => description}, socket) do
    suggestions =
      Enum.filter(socket.assigns.asset_suggestions, fn s -> s.description != description end)
      |> Enum.to_list()

    {:noreply, socket |> assign(asset_suggestions: suggestions)}
  end

  def handle_event("ignore_threat", %{"description" => description}, socket) do
    suggestions =
      Enum.filter(socket.assigns.threat_suggestions, fn s -> s.description != description end)
      |> Enum.to_list()

    {:noreply, socket |> assign(threat_suggestions: suggestions)}
  end

  @impl true
  def handle_event("add_asset", %{"name" => name, "description" => description}, socket) do
    user = socket.assigns.current_user
    org_id = socket.assigns.organisation.id

    {:ok, asset} = Assets.add_asset_with_name_and_description(user, org_id, name, description)

    suggestions =
      Enum.filter(socket.assigns.asset_suggestions, fn s -> s.description != description end)
      |> Enum.to_list()

    stale_organisation = socket.assigns.organisation
    updated_organisation = %{stale_organisation | assets: stale_organisation.assets ++ [asset]}

    {:noreply,
     socket
     |> assign(:organisation, updated_organisation)
     |> assign(:asset_suggestions, suggestions)}
  end

  @impl true
  def handle_event("add_threat", %{"name" => name, "description" => description}, socket) do
    user = socket.assigns.current_user
    org_id = socket.assigns.organisation.id

    {:ok, threat} = Threats.add_threat_with_name_and_description(user, org_id, name, description)

    suggestions =
      Enum.filter(socket.assigns.threat_suggestions, fn s -> s.description != description end)
      |> Enum.to_list()

    stale_organisation = socket.assigns.organisation
    updated_organisation = %{stale_organisation | threats: stale_organisation.threats ++ [threat]}

    {:noreply,
     socket
     |> assign(:organisation, updated_organisation)
     |> assign(:threat_suggestions, suggestions)}
  end

  defp ask_ai_for_assets(user, org_id) do
    organisation = Assets.get_organisation!(user, org_id)

    new_assets =
      AI.suggest_assets_for_organisation(organisation)

    {:ai_results_assets, new_assets}
  end

  defp ask_ai_for_threats(user, org_id) do
    organisation = Threats.get_organisation!(user, org_id)

    new_threats =
      AI.suggest_threats_for_organisation(organisation)

    {:ai_results_threats, new_threats}
  end

  defp start_threat_suggestions(org_id, socket) do
    user = socket.assigns.current_user

    task =
      Task.Supervisor.async_nolink(ThreatShield.TaskSupervisor, fn ->
        ask_ai_for_threats(user, org_id)
      end)

    socket =
      socket
      |> assign(asking_ai_for_threats: task.ref)

    socket
  end
end
