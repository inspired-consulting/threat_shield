defmodule ThreatShieldWeb.SystemLive.Show do
  require Logger
  alias ThreatShield.Organisations.Organisation
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Systems

  alias ThreatShield.Assets
  alias ThreatShield.Threats
  alias ThreatShield.AI
  alias ThreatShield.Systems.System
  import ThreatShieldWeb.Helpers, only: [add_breadcrumbs: 2]

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
     |> assign(:asset_suggestions, [])
     |> assign(:ai_suggestions, %{})}
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

  def handle_info({task_ref, {:ai_suggestion, suggestion}}, socket) do
    %{type: entity_type, result: result} = suggestion

    # stop monitoring the task
    Process.demonitor(task_ref, [:flush])

    Logger.debug("Got AI suggeston form: #{inspect(suggestion)}")

    suggestions =
      (socket.assigns[:suggestions] || %{})
      |> Map.put(entity_type, result)

    {:noreply,
     socket
     |> assign(ai_suggestions: suggestions)}
  end

  def handle_event("delete", %{"sys_id" => id}, socket) do
    current_user = socket.assigns.current_user

    {1, [_sys | _]} = Systems.delete_sys_by_id!(current_user, id)

    {:noreply,
     push_navigate(socket,
       to: "/organisations/#{socket.assigns.organisation.id}"
     )}
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
end
