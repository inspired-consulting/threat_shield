defmodule ThreatShieldWeb.SystemLive.Show do
  alias ThreatShield.Organisations.Organisation
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Systems

  alias ThreatShield.Assets
  alias ThreatShield.Threats.Threat
  alias ThreatShield.Threats
  alias ThreatShield.AI
  alias ThreatShield.Systems.System
  import ThreatShieldWeb.Helpers, only: [add_breadcrumbs: 2]
  import ThreatShield.Assets.Asset, only: [list_system_options: 1]

  @impl true
  def mount(%{"sys_id" => id}, _session, socket) do
    user = socket.assigns.current_user

    system = Systems.get_system!(user, id)

    {:ok,
     socket
     |> assign(:system, system)
     |> assign(:organisation, system.organisation)
     |> assign(:membership, Organisation.get_membership(system.organisation, user))
     |> assign(:attributes, System.attributes())
     |> assign(:asking_ai_for_assets, nil)
     |> assign(:asking_ai_for_threats, nil)
     |> assign(:asset_suggestions, [])
     |> assign(:threat_suggestions, [])}
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
    |> assign(:page_title, "Show System")
  end

  defp apply_action(socket, :edit_system, _params) do
    socket
    |> assign(:page_title, "Edit System")
  end

  defp apply_action(socket, :new_asset, _params) do
    current_system = socket.assigns.system

    socket
    |> assign(:page_title, "New Asset")
    |> assign(:asset, Assets.prepare_asset(current_system.id))
  end

  defp apply_action(socket, :new_threat, _params) do
    socket
    |> assign(:page_title, "New Threat")
    |> assign(:threat, %Threat{})
  end

  @impl true
  def handle_info(
        {ThreatShieldWeb.SystemLive.SystemForm, {:saved, system}},
        socket
      ) do
    user = socket.assigns.current_user
    system = Systems.get_system!(user, system.id)

    {:noreply,
     socket
     |> assign(system: system)
     |> assign(organisation: system.organisation)
     |> assign(page_title: "Show System")}
  end

  @impl true
  def handle_info({ThreatShieldWeb.AssetLive.AssetForm, {:saved, asset}}, socket) do
    stale_sys = socket.assigns.system
    updated_sys = %{stale_sys | assets: stale_sys.assets ++ [asset]}

    {:noreply, socket |> assign(system: updated_sys) |> assign(page_title: "Show System")}
  end

  @impl true
  def handle_info({ThreatShieldWeb.ThreatLive.ThreatForm, {:saved, threat}}, socket) do
    stale_sys = socket.assigns.system
    updated_sys = %{stale_sys | threats: stale_sys.threats ++ [threat]}

    {:noreply, socket |> assign(system: updated_sys) |> assign(page_title: "Show System")}
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

  def handle_info({_from, {:ai_results_threats, threats}}, socket) do
    %{asking_ai_for_threats: ref} = socket.assigns

    Process.demonitor(ref, [:flush])

    {:noreply,
     socket
     |> assign(
       asking_ai_for_threats: nil,
       threat_suggestions: socket.assigns.threat_suggestions ++ threats
     )}
  end

  @impl true
  def handle_event("delete", %{"sys_id" => id}, socket) do
    current_user = socket.assigns.current_user

    {1, [_sys | _]} = Systems.delete_sys_by_id!(current_user, id)

    {:noreply,
     push_navigate(socket,
       to: "/organisations/#{socket.assigns.organisation.id}"
     )}
  end

  @impl true
  def handle_event("suggest_assets", %{"sys_id" => sys_id}, socket) do
    user = socket.assigns.current_user

    task =
      Task.Supervisor.async_nolink(ThreatShield.TaskSupervisor, fn ->
        ask_ai_for_assets(user, sys_id)
      end)

    socket =
      socket
      |> assign(asking_ai_for_assets: task.ref)

    {:noreply, socket}
  end

  @impl true
  def handle_event("suggest_threats", %{"sys_id" => sys_id}, socket) do
    user = socket.assigns.current_user

    task =
      Task.Supervisor.async_nolink(ThreatShield.TaskSupervisor, fn ->
        ask_ai_for_threats(user, sys_id)
      end)

    socket =
      socket
      |> assign(asking_ai_for_threats: task.ref)

    {:noreply, socket}
  end

  @impl true
  def handle_event("ignore_asset", %{"description" => description}, socket) do
    suggestions =
      Enum.filter(socket.assigns.asset_suggestions, fn s -> s.description != description end)
      |> Enum.to_list()

    {:noreply, socket |> assign(asset_suggestions: suggestions)}
  end

  @impl true
  def handle_event("ignore_threat", %{"description" => description}, socket) do
    suggestions =
      Enum.filter(socket.assigns.threat_suggestions, fn s -> s.description != description end)
      |> Enum.to_list()

    {:noreply, socket |> assign(threat_suggestions: suggestions)}
  end

  @impl true
  def handle_event("add_asset", %{"name" => name, "description" => description}, socket) do
    user = socket.assigns.current_user
    system = socket.assigns.system

    {:ok, asset} = Assets.add_asset_with_name_and_description(user, system, name, description)

    suggestions =
      Enum.filter(socket.assigns.asset_suggestions, fn s -> s.description != description end)
      |> Enum.to_list()

    stale_sys = socket.assigns.system
    updated_sys = %{stale_sys | assets: stale_sys.assets ++ [asset]}

    {:noreply,
     socket
     |> assign(:system, updated_sys)
     |> assign(:asset_suggestions, suggestions)}
  end

  @impl true
  def handle_event("add_threat", %{"name" => name, "description" => description}, socket) do
    user = socket.assigns.current_user
    system = socket.assigns.system

    {:ok, threat} = Threats.add_threat_with_name_and_description(user, system, name, description)

    suggestions =
      Enum.filter(socket.assigns.threat_suggestions, fn s -> s.description != description end)
      |> Enum.to_list()

    stale_sys = socket.assigns.system
    updated_sys = %{stale_sys | threats: stale_sys.threats ++ [threat]}

    {:noreply,
     socket
     |> assign(:system, updated_sys)
     |> assign(:threat_suggestions, suggestions)}
  end

  defp ask_ai_for_assets(user, sys_id) do
    system = Systems.get_system!(user, sys_id)

    new_assets =
      AI.suggest_assets_for_system(system)

    {:ai_results_assets, new_assets}
  end

  defp ask_ai_for_threats(user, sys_id) do
    system = Systems.get_system!(user, sys_id)

    new_threats =
      AI.suggest_threats_for_system(system)

    {:ai_results_threats, new_threats}
  end
end
